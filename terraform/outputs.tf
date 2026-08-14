# =============================================================================
# Outputs Principais do ToggleMaster
# =============================================================================

# =============================================================================
# Networking
# =============================================================================

output "vpc_id" {
  description = "ID da VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR da VPC"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.networking.private_subnet_ids
}

# =============================================================================
# EKS
# =============================================================================

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Certificate Authority do cluster EKS"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_configure_kubectl" {
  description = "Comando para configurar kubectl"
  value       = module.eks.configure_kubectl
}

# =============================================================================
# RDS
# =============================================================================

output "rds_endpoints" {
  description = "Endpoints das instâncias RDS"
  value       = module.rds.db_endpoints
}

output "rds_secrets_names" {
  description = "Nomes dos secrets com credenciais RDS"
  value       = module.rds.secrets_names
}

output "rds_connection_info" {
  description = "Informações de conexão para os microsserviços"
  value       = module.rds.connection_info
}

# =============================================================================
# ElastiCache (Redis)
# =============================================================================

output "redis_endpoint" {
  description = "Endpoint do Redis"
  value       = module.elasticache.primary_endpoint
}

output "redis_url" {
  description = "URL de conexão do Redis"
  value       = module.elasticache.redis_url
}

# =============================================================================
# DynamoDB
# =============================================================================

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB"
  value       = module.dynamodb.table_arn
}

# =============================================================================
# SQS
# =============================================================================

output "sqs_queue_url" {
  description = "URL da fila SQS"
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "ARN da fila SQS"
  value       = module.sqs.queue_arn
}

output "sqs_dlq_url" {
  description = "URL da Dead Letter Queue"
  value       = module.sqs.dlq_url
}

# =============================================================================
# ECR
# =============================================================================

output "ecr_repository_urls" {
  description = "URLs dos repositórios ECR"
  value       = module.ecr.repository_urls
}

output "ecr_registry_url" {
  description = "URL base do registry ECR"
  value       = module.ecr.registry_url
}

output "ecr_docker_login_command" {
  description = "Comando para login no ECR"
  value       = module.ecr.docker_login_command
}

# =============================================================================
# Resumo para CI/CD e GitOps
# =============================================================================

output "ci_cd_config" {
  description = "Configuração completa para CI/CD"
  value = {
    aws_region   = var.aws_region
    cluster_name = module.eks.cluster_name
    ecr_registry = module.ecr.registry_url
    ecr_repos    = module.ecr.repository_urls
  }
}

output "kubernetes_config" {
  description = "Configuração para deployments Kubernetes"
  value = {
    # Database URLs (buscar senha do Secrets Manager)
    auth_db_host      = module.rds.db_addresses["auth"]
    flags_db_host     = module.rds.db_addresses["flags"]
    targeting_db_host = module.rds.db_addresses["targeting"]

    # Redis
    redis_url = module.elasticache.redis_url

    # AWS Services
    sqs_url        = module.sqs.queue_url
    dynamodb_table = module.dynamodb.table_name

    # Secrets Manager names (para External Secrets ou similar)
    secrets = module.rds.secrets_names
  }
}
