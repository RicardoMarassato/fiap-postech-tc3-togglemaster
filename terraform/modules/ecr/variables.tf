# =============================================================================
# Variáveis do Módulo ECR
# =============================================================================

variable "name_prefix" {
  description = "Prefixo para nomes dos recursos"
  type        = string
}

variable "repositories" {
  description = "Lista de repositórios a serem criados"
  type        = list(string)
  default = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service"
  ]
}

# =============================================================================
# Configuração dos Repositórios
# =============================================================================

variable "image_tag_mutability" {
  description = "Mutabilidade das tags (MUTABLE ou IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability deve ser MUTABLE ou IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Habilitar scan de vulnerabilidades no push"
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "Permite deletar repositório mesmo com imagens"
  type        = bool
  default     = false  # Proteção para prod
}

# =============================================================================
# Lifecycle Policy
# =============================================================================

variable "enable_lifecycle_policy" {
  description = "Habilitar política de ciclo de vida"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Número máximo de imagens a manter (untagged)"
  type        = number
  default     = 10
}

variable "max_tagged_image_count" {
  description = "Número máximo de imagens tagged a manter"
  type        = number
  default     = 30
}
