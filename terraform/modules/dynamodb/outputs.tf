# =============================================================================
# Outputs do Módulo DynamoDB
# =============================================================================

output "table_name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.analytics.name
}

output "table_id" {
  description = "ID da tabela DynamoDB"
  value       = aws_dynamodb_table.analytics.id
}

output "table_arn" {
  description = "ARN da tabela DynamoDB"
  value       = aws_dynamodb_table.analytics.arn
}

output "hash_key" {
  description = "Chave primária (partition key)"
  value       = aws_dynamodb_table.analytics.hash_key
}

output "billing_mode" {
  description = "Modo de cobrança da tabela"
  value       = aws_dynamodb_table.analytics.billing_mode
}

output "stream_arn" {
  description = "ARN do DynamoDB Stream (se habilitado)"
  value       = aws_dynamodb_table.analytics.stream_arn
}

output "stream_label" {
  description = "Label do DynamoDB Stream (se habilitado)"
  value       = aws_dynamodb_table.analytics.stream_label
}

output "gsi_names" {
  description = "Nomes dos Global Secondary Indexes"
  value       = [for gsi in aws_dynamodb_table.analytics.global_secondary_index : gsi.name]
}
