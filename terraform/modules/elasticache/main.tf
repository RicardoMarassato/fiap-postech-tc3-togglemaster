# =============================================================================
# Módulo: ElastiCache
# Cria Cluster Redis para o Evaluation Service (cache de flags)
# =============================================================================

# -----------------------------------------------------------------------------
# Subnet Group para ElastiCache
# -----------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.name_prefix}-redis-subnet-group"
  description = "Subnet group para ElastiCache Redis"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.name_prefix}-redis-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# Security Group para ElastiCache
# -----------------------------------------------------------------------------
resource "aws_security_group" "redis" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Security group para ElastiCache Redis"
  vpc_id      = var.vpc_id

  # Permite acesso Redis dos security groups especificados (EKS nodes)
  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      security_group_id        = ingress.value
      description              = "Redis access from allowed security group"
    }
  }

  # Permite acesso interno
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    self        = true
    description = "Redis access from self"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-redis-sg"
  }
}

# -----------------------------------------------------------------------------
# Parameter Group para Redis
# -----------------------------------------------------------------------------
resource "aws_elasticache_parameter_group" "redis" {
  name        = "${var.name_prefix}-redis-params"
  family      = "redis7"
  description = "Parameter group para Redis 7"

  # Configurações otimizadas para feature flags
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"  # Remove chaves menos usadas quando memória cheia
  }

  tags = {
    Name = "${var.name_prefix}-redis-params"
  }
}

# -----------------------------------------------------------------------------
# ElastiCache Cluster (Redis)
# -----------------------------------------------------------------------------
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.name_prefix}-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  # Manutenção
  maintenance_window = var.maintenance_window

  # Snapshot (backup)
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window

  # Atualizações automáticas
  auto_minor_version_upgrade = true

  # Notificações (opcional)
  # notification_topic_arn = var.sns_topic_arn

  tags = {
    Name = "${var.name_prefix}-redis"
  }
}
