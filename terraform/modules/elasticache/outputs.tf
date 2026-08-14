# =============================================================================
# Outputs do Módulo ElastiCache
# =============================================================================

output "cluster_id" {
  description = "ID do cluster Redis"
  value       = aws_elasticache_cluster.redis.cluster_id
}

output "cluster_arn" {
  description = "ARN do cluster Redis"
  value       = aws_elasticache_cluster.redis.arn
}

output "cache_nodes" {
  description = "Lista de cache nodes"
  value       = aws_elasticache_cluster.redis.cache_nodes
}

output "primary_endpoint" {
  description = "Endpoint primário do Redis"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "port" {
  description = "Porta do Redis"
  value       = aws_elasticache_cluster.redis.port
}

output "redis_url" {
  description = "URL de conexão do Redis"
  value       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
}

output "security_group_id" {
  description = "ID do security group do Redis"
  value       = aws_security_group.redis.id
}

output "subnet_group_name" {
  description = "Nome do subnet group"
  value       = aws_elasticache_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Nome do parameter group"
  value       = aws_elasticache_parameter_group.redis.name
}

output "engine_version" {
  description = "Versão do Redis"
  value       = aws_elasticache_cluster.redis.engine_version
}
