# =============================================================================
# Outputs do Módulo EKS
# =============================================================================

output "cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data do cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "Versão do Kubernetes do cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "ID do security group do cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "ID do security group dos worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "node_group_id" {
  description = "ID do node group"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN do node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status do node group"
  value       = aws_eks_node_group.main.status
}

# Comando para configurar kubectl
output "configure_kubectl" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
}

# Data source para região atual
data "aws_region" "current" {}
