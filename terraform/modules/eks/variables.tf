# =============================================================================
# Variáveis do Módulo EKS
# =============================================================================

variable "name_prefix" {
  description = "Prefixo para nomes dos recursos"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets para o cluster (públicas e/ou privadas)"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "IDs das subnets para os worker nodes (geralmente privadas)"
  type        = list(string)
}

# =============================================================================
# AWS Academy LabRole
# =============================================================================

variable "use_lab_role" {
  description = "Se true, usa LabRole existente do AWS Academy"
  type        = bool
  default     = true
}

variable "lab_role_arn" {
  description = "ARN da LabRole do AWS Academy"
  type        = string
}

# =============================================================================
# Node Group Configuration
# =============================================================================

variable "node_instance_types" {
  description = "Tipos de instância para os worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Número desejado de nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Número máximo de nodes"
  type        = number
  default     = 4
}

variable "node_disk_size" {
  description = "Tamanho do disco dos nodes (GB)"
  type        = number
  default     = 20
}

variable "node_capacity_type" {
  description = "Tipo de capacidade (ON_DEMAND ou SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

# =============================================================================
# Endpoint Access
# =============================================================================

variable "endpoint_public_access" {
  description = "Habilitar acesso público ao endpoint do cluster"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Habilitar acesso privado ao endpoint do cluster"
  type        = bool
  default     = true
}
