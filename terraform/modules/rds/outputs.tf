# =============================================================================
# Outputs do Módulo RDS
# =============================================================================

output "db_instances" {
  description = "Informações das instâncias RDS"
  value = {
    for name, db in aws_db_instance.databases : name => {
      id         = db.id
      identifier = db.identifier
      endpoint   = db.endpoint
      address    = db.address
      port       = db.port
      db_name    = db.db_name
      username   = db.username
      arn        = db.arn
    }
  }
}

output "db_endpoints" {
  description = "Endpoints das instâncias RDS"
  value = {
    for name, db in aws_db_instance.databases : name => db.endpoint
  }
}

output "db_addresses" {
  description = "Endereços (hostnames) das instâncias RDS"
  value = {
    for name, db in aws_db_instance.databases : name => db.address
  }
}

output "security_group_id" {
  description = "ID do security group do RDS"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Nome do DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "secrets_arns" {
  description = "ARNs dos secrets com credenciais"
  value = {
    for name, secret in aws_secretsmanager_secret.db_credentials : name => secret.arn
  }
}

output "secrets_names" {
  description = "Nomes dos secrets com credenciais"
  value = {
    for name, secret in aws_secretsmanager_secret.db_credentials : name => secret.name
  }
}

# Connection strings para uso nos microsserviços (sem expor a senha)
output "connection_info" {
  description = "Informações de conexão para os microsserviços"
  value = {
    for name, db in var.databases : name => {
      host     = aws_db_instance.databases[name].address
      port     = 5432
      database = db.db_name
      username = db.username
      secret   = aws_secretsmanager_secret.db_credentials[name].name
    }
  }
}
