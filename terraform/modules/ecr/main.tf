# =============================================================================
# Módulo: ECR
# Cria 5 repositórios para os microsserviços do ToggleMaster
# =============================================================================

# -----------------------------------------------------------------------------
# Repositórios ECR
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repositories)

  name                 = "${var.name_prefix}/${each.value}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Encryption com chave gerenciada pela AWS
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.name_prefix}-${each.value}"
    Service = each.value
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Policy - Limpa imagens antigas
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "repos" {
  for_each = var.enable_lifecycle_policy ? toset(var.repositories) : []

  repository = aws_ecr_repository.repos[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remover imagens untagged após ${var.max_image_count} imagens"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Manter apenas ${var.max_tagged_image_count} imagens tagged mais recentes"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "dev", "staging", "prod"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_tagged_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Data source para account ID (usado nos outputs)
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
