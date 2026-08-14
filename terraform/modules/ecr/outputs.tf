# =============================================================================
# Outputs do Módulo ECR
# =============================================================================

output "repository_urls" {
  description = "URLs dos repositórios ECR"
  value = {
    for name, repo in aws_ecr_repository.repos : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "ARNs dos repositórios ECR"
  value = {
    for name, repo in aws_ecr_repository.repos : name => repo.arn
  }
}

output "repository_names" {
  description = "Nomes completos dos repositórios ECR"
  value = {
    for name, repo in aws_ecr_repository.repos : name => repo.name
  }
}

output "registry_id" {
  description = "ID do registry ECR (Account ID)"
  value       = data.aws_caller_identity.current.account_id
}

output "registry_url" {
  description = "URL base do registry ECR"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

# Output útil para CI/CD - comando de login
output "docker_login_command" {
  description = "Comando para login no ECR via Docker"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

# Output para GitHub Actions - formato para usar diretamente
output "ecr_config" {
  description = "Configuração ECR para uso em CI/CD"
  value = {
    registry    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    region      = data.aws_region.current.name
    repositories = {
      for name, repo in aws_ecr_repository.repos : name => {
        url  = repo.repository_url
        name = repo.name
      }
    }
  }
}
