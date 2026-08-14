# =============================================================================
# Módulo: RDS
# Cria 3 instâncias PostgreSQL para auth, flags e targeting services
# =============================================================================

# -----------------------------------------------------------------------------
# Gerador de senhas aleatórias
# -----------------------------------------------------------------------------
resource "random_password" "db_passwords" {
  for_each = { for db in var.databases : db.name => db }

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${var.name_prefix}-db-subnet-group"
  description = "Subnet group para instâncias RDS do ToggleMaster"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# Security Group para RDS
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Security group para instâncias RDS"
  vpc_id      = var.vpc_id

  # Permite acesso PostgreSQL dos security groups especificados (EKS nodes)
  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      security_group_id        = ingress.value
      description              = "PostgreSQL access from allowed security group"
    }
  }

  # Permite acesso interno (entre instâncias RDS se necessário)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
    description = "PostgreSQL access from self"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

# -----------------------------------------------------------------------------
# Instâncias RDS PostgreSQL
# -----------------------------------------------------------------------------
resource "aws_db_instance" "databases" {
  for_each = { for db in var.databases : db.name => db }

  identifier = "${var.name_prefix}-${each.value.name}-db"

  # Engine
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = each.value.db_name
  username = each.value.username
  password = random_password.db_passwords[each.key].result

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible
  port                   = 5432

  # Availability
  multi_az = var.multi_az

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Deletion
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-${each.value.name}-final-snapshot"

  # Performance Insights (gratuito no t3.micro)
  performance_insights_enabled = true

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = {
    Name    = "${var.name_prefix}-${each.value.name}-db"
    Service = each.value.name
  }
}

# -----------------------------------------------------------------------------
# Parameter Group para PostgreSQL
# -----------------------------------------------------------------------------
resource "aws_db_parameter_group" "postgres" {
  name        = "${var.name_prefix}-postgres-params"
  family      = "postgres16"
  description = "Parameter group para PostgreSQL 16"

  # Configurações otimizadas
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries > 1s
  }

  tags = {
    Name = "${var.name_prefix}-postgres-params"
  }
}

# -----------------------------------------------------------------------------
# Secrets no AWS Secrets Manager (para armazenar credenciais)
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_credentials" {
  for_each = { for db in var.databases : db.name => db }

  name        = "${var.name_prefix}/${each.value.name}-db-credentials"
  description = "Credenciais do banco ${each.value.name}"

  tags = {
    Name    = "${var.name_prefix}-${each.value.name}-db-credentials"
    Service = each.value.name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  for_each = { for db in var.databases : db.name => db }

  secret_id = aws_secretsmanager_secret.db_credentials[each.key].id
  secret_string = jsonencode({
    username = each.value.username
    password = random_password.db_passwords[each.key].result
    host     = aws_db_instance.databases[each.key].address
    port     = 5432
    database = each.value.db_name
    url      = "postgresql://${each.value.username}:${random_password.db_passwords[each.key].result}@${aws_db_instance.databases[each.key].address}:5432/${each.value.db_name}"
  })
}
