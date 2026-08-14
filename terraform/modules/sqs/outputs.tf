# =============================================================================
# Outputs do Módulo SQS
# =============================================================================

output "queue_id" {
  description = "ID (URL) da fila SQS"
  value       = aws_sqs_queue.main.id
}

output "queue_url" {
  description = "URL da fila SQS"
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN da fila SQS"
  value       = aws_sqs_queue.main.arn
}

output "queue_name" {
  description = "Nome da fila SQS"
  value       = aws_sqs_queue.main.name
}

output "dlq_id" {
  description = "ID (URL) da Dead Letter Queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].id : null
}

output "dlq_url" {
  description = "URL da Dead Letter Queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "ARN da Dead Letter Queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_name" {
  description = "Nome da Dead Letter Queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].name : null
}

# Para uso no código da aplicação
output "sqs_config" {
  description = "Configuração completa da fila para uso na aplicação"
  value = {
    url                 = aws_sqs_queue.main.url
    arn                 = aws_sqs_queue.main.arn
    name                = aws_sqs_queue.main.name
    visibility_timeout  = var.visibility_timeout_seconds
    message_retention   = var.message_retention_seconds
    dlq_url             = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
    max_receive_count   = var.max_receive_count
  }
}
