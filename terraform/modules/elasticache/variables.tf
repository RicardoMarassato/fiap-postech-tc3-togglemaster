# =============================================================================
# Variáveis do Módulo ElastiCache
# =============================================================================

variable "name_prefix" {
  description = "Prefixo para nomes dos recursos"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets para o Subnet Group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "IDs dos security groups que podem acessar o Redis (ex: EKS nodes)"
  type        = list(string)
  default     = []
}

# =============================================================================
# Configuração do Cluster
# =============================================================================

variable "node_type" {
  description = "Tipo de node para o ElastiCache"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Número de nodes no cluster"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Versão do Redis"
  type        = string
  default     = "7.1"
}

# =============================================================================
# Manutenção e Backup
# =============================================================================

variable "maintenance_window" {
  description = "Janela de manutenção (UTC)"
  type        = string
  default     = "mon:05:00-mon:06:00"
}

variable "snapshot_retention_limit" {
  description = "Dias de retenção de snapshots (0 = desabilitado)"
  type        = number
  default     = 1
}

variable "snapshot_window" {
  description = "Janela de snapshot (UTC)"
  type        = string
  default     = "03:00-04:00"
}
