# =============================================================================
# Variáveis do Módulo RDS
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
  description = "IDs das subnets para o DB Subnet Group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "IDs dos security groups que podem acessar o RDS (ex: EKS nodes)"
  type        = list(string)
  default     = []
}

# =============================================================================
# Configuração dos Bancos
# =============================================================================

variable "databases" {
  description = "Lista de bancos de dados a serem criados"
  type = list(object({
    name        = string  # Identificador único (ex: auth, flags, targeting)
    db_name     = string  # Nome do database
    username    = string  # Usuário admin
  }))
  default = [
    { name = "auth", db_name = "auth_db", username = "auth_admin" },
    { name = "flags", db_name = "flags_db", username = "flags_admin" },
    { name = "targeting", db_name = "targeting_db", username = "targeting_admin" }
  ]
}

# =============================================================================
# Configuração das Instâncias
# =============================================================================

variable "instance_class" {
  description = "Classe de instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Armazenamento máximo para autoscaling (0 = desabilitado)"
  type        = number
  default     = 100
}

variable "engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "16.3"
}

variable "multi_az" {
  description = "Habilitar Multi-AZ"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Tornar RDS acessível publicamente"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Proteção contra deleção"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Pular snapshot final ao deletar"
  type        = bool
  default     = true  # true para dev, false para prod
}

variable "backup_retention_period" {
  description = "Dias de retenção de backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Janela de backup (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Janela de manutenção"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}
