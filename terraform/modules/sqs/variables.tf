# =============================================================================
# Variáveis do Módulo SQS
# =============================================================================

variable "name_prefix" {
  description = "Prefixo para nomes dos recursos"
  type        = string
}

variable "queue_name" {
  description = "Nome da fila SQS"
  type        = string
  default     = "togglemaster-events"
}

# =============================================================================
# Configuração da Fila
# =============================================================================

variable "visibility_timeout_seconds" {
  description = "Tempo que a mensagem fica invisível após ser lida (segundos)"
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  description = "Tempo de retenção de mensagens (segundos, max 14 dias = 1209600)"
  type        = number
  default     = 345600  # 4 dias
}

variable "max_message_size" {
  description = "Tamanho máximo de mensagem (bytes, max 256KB)"
  type        = number
  default     = 262144  # 256 KB
}

variable "delay_seconds" {
  description = "Delay de entrega de mensagens (segundos)"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Tempo de espera para long polling (segundos)"
  type        = number
  default     = 10  # Long polling habilitado
}

# =============================================================================
# Dead Letter Queue (DLQ)
# =============================================================================

variable "enable_dlq" {
  description = "Habilitar Dead Letter Queue"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Número máximo de tentativas antes de mover para DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "Tempo de retenção de mensagens na DLQ (segundos)"
  type        = number
  default     = 1209600  # 14 dias (máximo)
}

# =============================================================================
# Encryption
# =============================================================================

variable "sqs_managed_sse_enabled" {
  description = "Habilitar Server-Side Encryption gerenciada pelo SQS"
  type        = bool
  default     = true
}
