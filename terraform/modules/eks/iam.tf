# =============================================================================
# Módulo: EKS - IAM Roles (Conta Pessoal / Sem LabRole)
# =============================================================================
# Criadas automaticamente quando use_lab_role = false.
# Se use_lab_role = true (AWS Academy), estas roles são ignoradas e a LabRole é usada.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Role para o Cluster EKS (Control Plane)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  count = var.use_lab_role ? 0 : 1
  name  = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  count      = var.use_lab_role ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

# -----------------------------------------------------------------------------
# 2. Role para os Worker Nodes (Node Group)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "node" {
  count = var.use_lab_role ? 0 : 1
  name  = "${var.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-eks-node-role"
  }
}

# Políticas gerenciadas padrão para worker nodes do EKS
resource "aws_iam_role_policy_attachment" "node_worker" {
  count      = var.use_lab_role ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  count      = var.use_lab_role ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  count      = var.use_lab_role ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[0].name
}

# Permissões para os pods acessarem SQS e DynamoDB via Node Role
resource "aws_iam_role_policy_attachment" "node_sqs" {
  count      = var.use_lab_role ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_dynamodb" {
  count      = var.use_lab_role ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.node[0].name
}
