# API Gateway para comunicación Front-Back
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "API Gateway para ${var.project_name} - Comunicación Front-Back"

  cors_configuration {
    allow_credentials = true
    allow_headers     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"]
    allow_origins     = var.cors_origins
    expose_headers    = ["*"]
    max_age           = 3600
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = "all"
  }
}

# Stage para DEV
resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit    = 100
    throttling_rate_limit     = 50
  }

  tags = {
    Name        = "${var.project_name}-api-dev"
    Environment = "dev"
  }
}

# Stage para PREPROD
resource "aws_apigatewayv2_stage" "preprod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "preprod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit    = 500
    throttling_rate_limit     = 200
  }

  tags = {
    Name        = "${var.project_name}-api-preprod"
    Environment = "preprod"
  }
}

# Stage para PROD
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit    = 1000
    throttling_rate_limit     = 500
  }

  tags = {
    Name        = "${var.project_name}-api-prod"
    Environment = "prod"
  }
}

# Integration con el Application Load Balancer
resource "aws_apigatewayv2_integration" "alb" {
  api_id = aws_apigatewayv2_api.main.id

  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "http://${var.load_balancer_dns}/"
  connection_type    = "INTERNET"

  payload_format_version = "1.0"
}

# Route por defecto (catch-all)
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# Route para todas las rutas
resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# CloudWatch Log Group para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-api-gateway-logs"
  }
}

# SNS Topic para eventos generales
resource "aws_sns_topic" "events" {
  name              = "${var.project_name}-events"
  display_name      = "${var.project_name} Events Topic"
  kms_master_key_id = var.enable_sns_encryption ? aws_kms_key.sns[0].arn : null

  tags = {
    Name        = "${var.project_name}-events-topic"
    Environment = "all"
  }
}

# SNS Topic para notificaciones
resource "aws_sns_topic" "notifications" {
  name              = "${var.project_name}-notifications"
  display_name      = "${var.project_name} Notifications Topic"
  kms_master_key_id = var.enable_sns_encryption ? aws_kms_key.sns[0].arn : null

  tags = {
    Name        = "${var.project_name}-notifications-topic"
    Environment = "all"
  }
}

# SNS Topic para procesamiento de datos
resource "aws_sns_topic" "data_processing" {
  name              = "${var.project_name}-data-processing"
  display_name      = "${var.project_name} Data Processing Topic"
  kms_master_key_id = var.enable_sns_encryption ? aws_kms_key.sns[0].arn : null

  tags = {
    Name        = "${var.project_name}-data-processing-topic"
    Environment = "all"
  }
}

# SQS Queue para procesamiento de eventos
resource "aws_sqs_queue" "events_queue" {
  name                      = "${var.project_name}-events-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600 # 4 días
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 30

  kms_master_key_id = var.enable_sqs_encryption ? aws_kms_key.sqs[0].arn : null

  tags = {
    Name        = "${var.project_name}-events-queue"
    Environment = "all"
  }
}

# SQS Queue para notificaciones
resource "aws_sqs_queue" "notifications_queue" {
  name                      = "${var.project_name}-notifications-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 30

  kms_master_key_id = var.enable_sqs_encryption ? aws_kms_key.sqs[0].arn : null

  tags = {
    Name        = "${var.project_name}-notifications-queue"
    Environment = "all"
  }
}

# SQS Queue para procesamiento de datos (DLQ - Dead Letter Queue)
resource "aws_sqs_queue" "data_processing_dlq" {
  name                      = "${var.project_name}-data-processing-dlq"
  message_retention_seconds = 1209600 # 14 días

  kms_master_key_id = var.enable_sqs_encryption ? aws_kms_key.sqs[0].arn : null

  tags = {
    Name        = "${var.project_name}-data-processing-dlq"
    Environment = "all"
  }
}

# SQS Queue principal para procesamiento de datos
resource "aws_sqs_queue" "data_processing_queue" {
  name                      = "${var.project_name}-data-processing-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 60

  # Dead Letter Queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.data_processing_dlq.arn
    maxReceiveCount     = 3
  })

  kms_master_key_id = var.enable_sqs_encryption ? aws_kms_key.sqs[0].arn : null

  tags = {
    Name        = "${var.project_name}-data-processing-queue"
    Environment = "all"
  }
}

# Suscripción SQS a SNS Topic (Events)
resource "aws_sns_topic_subscription" "events_to_queue" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.events_queue.arn
}

# Suscripción SQS a SNS Topic (Notifications)
resource "aws_sns_topic_subscription" "notifications_to_queue" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notifications_queue.arn
}

# Suscripción SQS a SNS Topic (Data Processing)
resource "aws_sns_topic_subscription" "data_processing_to_queue" {
  topic_arn = aws_sns_topic.data_processing.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.data_processing_queue.arn
}

# Política para permitir que SNS publique en SQS
resource "aws_sqs_queue_policy" "events_queue_policy" {
  queue_url = aws_sqs_queue.events_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.events_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.events.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "notifications_queue_policy" {
  queue_url = aws_sqs_queue.notifications_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.notifications_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.notifications.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "data_processing_queue_policy" {
  queue_url = aws_sqs_queue.data_processing_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.data_processing_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.data_processing.arn
          }
        }
      }
    ]
  })
}

# KMS Keys para encriptación (opcional)
resource "aws_kms_key" "sns" {
  count       = var.enable_sns_encryption ? 1 : 0
  description = "KMS key for SNS encryption - ${var.project_name}"

  tags = {
    Name = "${var.project_name}-sns-kms-key"
  }
}

resource "aws_kms_alias" "sns" {
  count         = var.enable_sns_encryption ? 1 : 0
  name          = "alias/${var.project_name}-sns"
  target_key_id = aws_kms_key.sns[0].key_id
}

resource "aws_kms_key" "sqs" {
  count       = var.enable_sqs_encryption ? 1 : 0
  description = "KMS key for SQS encryption - ${var.project_name}"

  tags = {
    Name = "${var.project_name}-sqs-kms-key"
  }
}

resource "aws_kms_alias" "sqs" {
  count         = var.enable_sqs_encryption ? 1 : 0
  name          = "alias/${var.project_name}-sqs"
  target_key_id = aws_kms_key.sqs[0].key_id
}

