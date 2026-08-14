# =============================================================================
# Módulo: SQS
# Cria fila de mensageria para eventos do ToggleMaster
# =============================================================================

# -----------------------------------------------------------------------------
# Dead Letter Queue (DLQ) - Para mensagens que falharam
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name = "${var.name_prefix}-${var.queue_name}-dlq"

  message_retention_seconds = var.dlq_message_retention_seconds

  # Encryption
  sqs_managed_sse_enabled = var.sqs_managed_sse_enabled

  tags = {
    Name = "${var.name_prefix}-${var.queue_name}-dlq"
    Type = "DLQ"
  }
}

# -----------------------------------------------------------------------------
# Fila Principal
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "main" {
  name = "${var.name_prefix}-${var.queue_name}"

  # Configuração de processamento
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # Encryption
  sqs_managed_sse_enabled = var.sqs_managed_sse_enabled

  # Redrive policy (DLQ)
  dynamic "redrive_policy" {
    for_each = var.enable_dlq ? [1] : []
    content {
      deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
      maxReceiveCount     = var.max_receive_count
    }
  }

  tags = {
    Name = "${var.name_prefix}-${var.queue_name}"
    Type = "Main"
  }
}

# -----------------------------------------------------------------------------
# Policy da DLQ para permitir a fila principal enviar mensagens
# -----------------------------------------------------------------------------
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.enable_dlq ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Alarm para DLQ (opcional mas recomendado)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count = var.enable_dlq ? 1 : 0

  alarm_name          = "${var.name_prefix}-${var.queue_name}-dlq-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300  # 5 minutos
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarme quando há mensagens na DLQ do ${var.queue_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq[0].name
  }

  tags = {
    Name = "${var.name_prefix}-${var.queue_name}-dlq-alarm"
  }
}
