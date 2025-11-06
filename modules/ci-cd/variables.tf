variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
}

variable "codecommit_repo_name" {
  description = "Nombre del repositorio CodeCommit"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "ID del Security Group de EC2"
  type        = string
}

variable "enable_pipelines" {
  description = "Habilitar pipelines de CI/CD"
  type        = bool
  default     = true
}

variable "artifacts_retention_days" {
  description = "Días de retención para artifacts en S3"
  type        = number
  default     = 30
}

variable "codebuild_environment_variables" {
  description = "Variables de entorno para CodeBuild (no sensibles)"
  type        = map(map(string))
  default = {
    dev     = {}
    preprod = {}
    prod    = {}
  }
}

variable "use_parameter_store" {
  description = "Habilitar uso de Parameter Store"
  type        = bool
  default     = true
}

variable "use_secrets_manager" {
  description = "Habilitar uso de Secrets Manager"
  type        = bool
  default     = false
}

variable "api_gateway_id" {
  description = "ID del API Gateway (opcional)"
  type        = string
  default     = null
}

variable "sns_events_topic_arn" {
  description = "ARN del SNS Events Topic (opcional)"
  type        = string
  default     = null
}

variable "sns_notifications_topic_arn" {
  description = "ARN del SNS Notifications Topic (opcional)"
  type        = string
  default     = null
}

variable "sns_data_processing_topic_arn" {
  description = "ARN del SNS Data Processing Topic (opcional)"
  type        = string
  default     = null
}

variable "sqs_events_queue_url" {
  description = "URL de la SQS Events Queue (opcional)"
  type        = string
  default     = null
}

variable "sqs_notifications_queue_url" {
  description = "URL de la SQS Notifications Queue (opcional)"
  type        = string
  default     = null
}

variable "sqs_data_processing_queue_url" {
  description = "URL de la SQS Data Processing Queue (opcional)"
  type        = string
  default     = null
}

variable "sns_topic_arns" {
  description = "Lista de ARNs de SNS Topics (opcional)"
  type        = list(string)
  default     = null
}

variable "sqs_queue_arns" {
  description = "Lista de ARNs de SQS Queues (opcional)"
  type        = list(string)
  default     = null
}

variable "parameter_store_dev_vars" {
  description = "Parámetros de Parameter Store para dev (opcional)"
  type        = map(string)
  default     = {}
}

variable "parameter_store_preprod_vars" {
  description = "Parámetros de Parameter Store para preprod (opcional)"
  type        = map(string)
  default     = {}
}

variable "parameter_store_prod_vars" {
  description = "Parámetros de Parameter Store para prod (opcional)"
  type        = map(string)
  default     = {}
}

variable "require_prod_approvals" {
  description = "Requerir aprobaciones manuales antes del despliegue a producción"
  type        = bool
  default     = true
}

variable "prod_approval_sns_topic_arn" {
  description = "ARN del SNS Topic para notificaciones de aprobación de producción (opcional)"
  type        = string
  default     = null
}

variable "require_prod_pr_approvals" {
  description = "Requerir 3 aprobaciones de PR antes de mergear a producción en CodeCommit"
  type        = bool
  default     = true
}

variable "prod_approvers_arn" {
  description = "Lista de ARNs de usuarios/grupos IAM que pueden aprobar PRs a producción (opcional, si está vacío cualquier usuario puede aprobar)"
  type        = list(string)
  default     = null
}

