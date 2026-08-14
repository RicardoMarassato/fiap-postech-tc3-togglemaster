# =============================================================================
# Data Sources
# =============================================================================

# Dados da conta AWS atual
data "aws_caller_identity" "current" {}

# Região atual
data "aws_region" "current" {}

# =============================================================================
# AWS Academy LabRole
# =============================================================================
# Para AWS Academy, a LabRole já existe e não podemos criar novas roles.
# Usamos data source para referenciar a role existente.

data "aws_iam_role" "lab_role" {
  count = var.use_lab_role ? 1 : 0
  name  = "LabRole"
}

# Local para facilitar referência ao ARN da LabRole
locals {
  # Se use_lab_role é true, usa o data source. Senão, usa a variável (para conta pessoal)
  lab_role_arn = var.use_lab_role ? data.aws_iam_role.lab_role[0].arn : var.lab_role_arn

  # Tags comuns
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Nome base para recursos
  name_prefix = "${var.project_name}-${var.environment}"
}
