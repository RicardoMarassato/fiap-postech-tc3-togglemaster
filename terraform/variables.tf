# =============================================================================
# Variáveis Globais
# =============================================================================

variable "aws_region" {
  description = "Região AWS para deploy dos recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "togglemaster"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# =============================================================================
# AWS Academy LabRole
# =============================================================================

variable "lab_role_arn" {
  description = "ARN da LabRole do AWS Academy (obrigatório para Academy)"
  type        = string
  default     = ""  # Será preenchido via terraform.tfvars ou variável de ambiente
}

variable "use_lab_role" {
  description = "Se true, usa LabRole existente. Se false, cria roles (conta pessoal)"
  type        = bool
  default     = true  # Default para AWS Academy
}

# =============================================================================
# Networking
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Lista de AZs para usar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# =============================================================================
# EKS
# =============================================================================

variable "eks_cluster_version" {
  description = "Versão do Kubernetes para o EKS"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "Tipos de instância para os worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Número desejado de nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Número máximo de nodes"
  type        = number
  default     = 4
}

# =============================================================================
# RDS (PostgreSQL)
# =============================================================================

variable "rds_instance_class" {
  description = "Classe de instância para o RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Armazenamento alocado para o RDS (GB)"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "16.3"
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ para o RDS"
  type        = bool
  default     = false  # false para economizar custos em dev
}

# =============================================================================
# ElastiCache (Redis)
# =============================================================================

variable "redis_node_type" {
  description = "Tipo de node para o ElastiCache Redis"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Número de nodes no cluster Redis"
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "Versão do Redis"
  type        = string
  default     = "7.1"
}

# =============================================================================
# DynamoDB
# =============================================================================

variable "dynamodb_billing_mode" {
  description = "Modo de cobrança do DynamoDB (PAY_PER_REQUEST ou PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

# =============================================================================
# ECR
# =============================================================================

variable "ecr_image_tag_mutability" {
  description = "Mutabilidade das tags de imagem (MUTABLE ou IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Habilitar scan de vulnerabilidades no push"
  type        = bool
  default     = true
}
