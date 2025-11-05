# ============================================
# NETWORKING OUTPUTS
# ============================================
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = module.networking.private_subnet_ids
}

# ============================================
# SECURITY OUTPUTS
# ============================================
output "alb_security_group_id" {
  description = "ID del Security Group del ALB"
  value       = module.security.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "ID del Security Group de EC2"
  value       = module.security.ec2_security_group_id
}

output "ec2_role_arn" {
  description = "ARN del rol IAM para EC2"
  value       = module.security.ec2_role_arn
}

# ============================================
# COMPUTE OUTPUTS
# ============================================
output "load_balancer_dns" {
  description = "DNS name del Application Load Balancer"
  value       = module.compute.load_balancer_dns
}

output "load_balancer_arn" {
  description = "ARN del Application Load Balancer"
  value       = module.compute.load_balancer_arn
}

output "load_balancer_id" {
  description = "ID del Application Load Balancer"
  value       = module.compute.load_balancer_id
}

output "auto_scaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = module.compute.auto_scaling_group_name
}

# ============================================
# CI/CD OUTPUTS
# ============================================
output "codecommit_repo_url" {
  description = "URL del repositorio CodeCommit"
  value       = module.ci_cd.codecommit_repo_url
}

output "codecommit_repo_arn" {
  description = "ARN del repositorio CodeCommit"
  value       = module.ci_cd.codecommit_repo_arn
}

output "codebuild_project_names" {
  description = "Nombres de los proyectos CodeBuild por entorno"
  value       = module.ci_cd.codebuild_project_names
}

output "codebuild_project_arns" {
  description = "ARNs de los proyectos CodeBuild por entorno"
  value       = module.ci_cd.codebuild_project_arns
}

output "codebuild_service_role_arn" {
  description = "ARN del rol de servicio de CodeBuild"
  value       = module.ci_cd.codebuild_service_role_arn
}

output "codepipeline_names" {
  description = "Nombres de los pipelines por entorno"
  value       = module.ci_cd.codepipeline_names
}

output "codepipeline_arns" {
  description = "ARNs de los pipelines por entorno"
  value       = module.ci_cd.codepipeline_arns
}

output "codepipeline_artifacts_bucket" {
  description = "Nombre del bucket S3 para artifacts de CodePipeline"
  value       = module.ci_cd.codepipeline_artifacts_bucket
}

output "codepipeline_service_role_arn" {
  description = "ARN del rol de servicio de CodePipeline"
  value       = module.ci_cd.codepipeline_service_role_arn
}

# ============================================
# MESSAGING OUTPUTS
# ============================================
output "api_gateway_id" {
  description = "ID del API Gateway"
  value       = module.messaging.api_gateway_id
}

output "api_gateway_urls" {
  description = "URLs del API Gateway por entorno"
  value       = module.messaging.api_gateway_urls
}

output "sns_topic_arns" {
  description = "ARNs de los SNS Topics"
  value       = module.messaging.sns_topic_arns
}

output "sns_events_topic_arn" {
  description = "ARN del SNS Events Topic"
  value       = module.messaging.sns_events_topic_arn
}

output "sns_notifications_topic_arn" {
  description = "ARN del SNS Notifications Topic"
  value       = module.messaging.sns_notifications_topic_arn
}

output "sns_data_processing_topic_arn" {
  description = "ARN del SNS Data Processing Topic"
  value       = module.messaging.sns_data_processing_topic_arn
}

output "sqs_queue_urls" {
  description = "URLs de las SQS Queues"
  value       = module.messaging.sqs_queue_urls
}

output "sqs_events_queue_url" {
  description = "URL de la SQS Events Queue"
  value       = module.messaging.sqs_events_queue_url
}

output "sqs_notifications_queue_url" {
  description = "URL de la SQS Notifications Queue"
  value       = module.messaging.sqs_notifications_queue_url
}

output "sqs_data_processing_queue_url" {
  description = "URL de la SQS Data Processing Queue"
  value       = module.messaging.sqs_data_processing_queue_url
}

output "sqs_queue_arns" {
  description = "ARNs de las SQS Queues"
  value       = module.messaging.sqs_queue_arns
}

# ============================================
# STORAGE OUTPUTS
# ============================================
output "parameter_store_dev_arns" {
  description = "ARNs de los parámetros de Parameter Store para dev"
  value       = module.storage.parameter_store_dev_arns
}

output "parameter_store_preprod_arns" {
  description = "ARNs de los parámetros de Parameter Store para preprod"
  value       = module.storage.parameter_store_preprod_arns
}

output "parameter_store_prod_arns" {
  description = "ARNs de los parámetros de Parameter Store para prod"
  value       = module.storage.parameter_store_prod_arns
}
