# =============================================================================
# Módulo: EKS
# Cria Cluster EKS e Node Groups usando LabRole (AWS Academy)
# =============================================================================

# -----------------------------------------------------------------------------
# Security Group para o Cluster EKS
# -----------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster" {
  name        = "${var.name_prefix}-eks-cluster-sg"
  description = "Security group para o cluster EKS"
  vpc_id      = var.vpc_id

  # Egress - permite tudo
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-eks-cluster-sg"
  }
}

# Regra de ingress para comunicação com os nodes
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow nodes to communicate with the cluster API Server"
}

# -----------------------------------------------------------------------------
# Security Group para os Worker Nodes
# -----------------------------------------------------------------------------
resource "aws_security_group" "eks_nodes" {
  name        = "${var.name_prefix}-eks-nodes-sg"
  description = "Security group para os worker nodes do EKS"
  vpc_id      = var.vpc_id

  # Egress - permite tudo
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                        = "${var.name_prefix}-eks-nodes-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Comunicação entre nodes
resource "aws_security_group_rule" "nodes_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow nodes to communicate with each other"
}

# Comunicação do cluster para os nodes
resource "aws_security_group_rule" "nodes_cluster_ingress" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
}

# Comunicação HTTPS do cluster para os nodes (para webhooks, etc)
resource "aws_security_group_rule" "nodes_cluster_ingress_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
}

locals {
  cluster_role_arn = var.use_lab_role ? var.lab_role_arn : aws_iam_role.cluster[0].arn
  node_role_arn    = var.use_lab_role ? var.lab_role_arn : aws_iam_role.node[0].arn
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = local.cluster_role_arn

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id]
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
  }

  # Desabilitado para economizar custos de ingestão no CloudWatch ($0.50/GB)
  enabled_cluster_log_types = []

  tags = {
    Name = var.cluster_name
  }

  depends_on = [
    aws_security_group.eks_cluster,
    aws_security_group.eks_nodes,
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

# -----------------------------------------------------------------------------
# EKS Node Group
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name_prefix}-node-group-v2"
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.node_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  # Labels para os nodes
  labels = {
    "role"        = "worker"
    "environment" = split("-", var.name_prefix)[1] # Extrai o environment do name_prefix
  }

  tags = {
    Name = "${var.name_prefix}-node-group-v2"
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr
  ]
}

# -----------------------------------------------------------------------------
# Configurar kubectl access (aws-auth ConfigMap é gerenciado pelo EKS automaticamente
# quando usando LabRole, não precisamos criar manualmente)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# EKS Addons (opcionais mas recomendados)
# -----------------------------------------------------------------------------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}
