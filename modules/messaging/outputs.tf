output "api_gateway_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.main.id
}

output "api_gateway_urls" {
  description = "URLs del API Gateway por entorno"
  value = {
    dev     = "https://${aws_apigatewayv2_api.main.api_id}.execute-api.${var.aws_region}.amazonaws.com/dev"
    preprod = "https://${aws_apigatewayv2_api.main.api_id}.execute-api.${var.aws_region}.amazonaws.com/preprod"
    prod    = "https://${aws_apigatewayv2_api.main.api_id}.execute-api.${var.aws_region}.amazonaws.com/prod"
  }
}

output "sns_events_topic_arn" {
  description = "ARN del SNS Events Topic"
  value       = aws_sns_topic.events.arn
}

output "sns_notifications_topic_arn" {
  description = "ARN del SNS Notifications Topic"
  value       = aws_sns_topic.notifications.arn
}

output "sns_data_processing_topic_arn" {
  description = "ARN del SNS Data Processing Topic"
  value       = aws_sns_topic.data_processing.arn
}

output "sns_topic_arns" {
  description = "ARNs de todos los SNS Topics"
  value = {
    events            = aws_sns_topic.events.arn
    notifications    = aws_sns_topic.notifications.arn
    data_processing  = aws_sns_topic.data_processing.arn
  }
}

output "sqs_events_queue_url" {
  description = "URL de la SQS Events Queue"
  value       = aws_sqs_queue.events_queue.url
}

output "sqs_notifications_queue_url" {
  description = "URL de la SQS Notifications Queue"
  value       = aws_sqs_queue.notifications_queue.url
}

output "sqs_data_processing_queue_url" {
  description = "URL de la SQS Data Processing Queue"
  value       = aws_sqs_queue.data_processing_queue.url
}

output "sqs_queue_urls" {
  description = "URLs de todas las SQS Queues"
  value = {
    events_queue            = aws_sqs_queue.events_queue.url
    notifications_queue     = aws_sqs_queue.notifications_queue.url
    data_processing_queue   = aws_sqs_queue.data_processing_queue.url
    data_processing_dlq     = aws_sqs_queue.data_processing_dlq.url
  }
}

output "sqs_queue_arns" {
  description = "ARNs de todas las SQS Queues"
  value = {
    events_queue            = aws_sqs_queue.events_queue.arn
    notifications_queue     = aws_sqs_queue.notifications_queue.arn
    data_processing_queue   = aws_sqs_queue.data_processing_queue.arn
    data_processing_dlq     = aws_sqs_queue.data_processing_dlq.arn
  }
}

