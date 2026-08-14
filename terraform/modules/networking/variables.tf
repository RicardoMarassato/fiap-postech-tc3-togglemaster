# =============================================================================
# Variáveis do Módulo Networking
# =============================================================================

variable "name_prefix" {
  description = "Prefixo para nomes dos recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
}

variable "availability_zones" {
  description = "Lista de Availability Zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
}

variable "cluster_name" {
  description = "Nome do cluster EKS (para tags das subnets)"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para subnets privadas"
  type        = bool
  default     = true
}
