# =============================================================================
# Variáveis do Módulo DynamoDB
# =============================================================================

variable "name_prefix" {
  description = "Prefixo para nomes dos recursos"
  type        = string
}

variable "table_name" {
  description = "Nome da tabela DynamoDB"
  type        = string
  default     = "ToggleMasterAnalytics"
}

# =============================================================================
# Billing Mode
# =============================================================================

variable "billing_mode" {
  description = "Modo de cobrança (PAY_PER_REQUEST ou PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode deve ser PAY_PER_REQUEST ou PROVISIONED."
  }
}

# =============================================================================
# Capacidade Provisionada (somente para PROVISIONED mode)
# =============================================================================

variable "read_capacity" {
  description = "Capacidade de leitura provisionada"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Capacidade de escrita provisionada"
  type        = number
  default     = 5
}

variable "gsi_read_capacity" {
  description = "Capacidade de leitura para GSIs"
  type        = number
  default     = 5
}

variable "gsi_write_capacity" {
  description = "Capacidade de escrita para GSIs"
  type        = number
  default     = 5
}

# =============================================================================
# Auto Scaling (somente para PROVISIONED mode)
# =============================================================================

variable "enable_autoscaling" {
  description = "Habilitar auto scaling para PROVISIONED mode"
  type        = bool
  default     = false
}

variable "autoscaling_max_read_capacity" {
  description = "Capacidade máxima de leitura para auto scaling"
  type        = number
  default     = 100
}

variable "autoscaling_max_write_capacity" {
  description = "Capacidade máxima de escrita para auto scaling"
  type        = number
  default     = 100
}

# =============================================================================
# Features
# =============================================================================

variable "enable_ttl" {
  description = "Habilitar TTL (Time To Live) para auto-expirar itens"
  type        = bool
  default     = true
}

variable "enable_point_in_time_recovery" {
  description = "Habilitar Point-in-Time Recovery"
  type        = bool
  default     = true
}

variable "enable_streams" {
  description = "Habilitar DynamoDB Streams"
  type        = bool
  default     = false
}
