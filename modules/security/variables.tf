variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitidos para acceso HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_messaging_permissions" {
  description = "Habilitar permisos para SNS y SQS"
  type        = bool
  default     = false
}

variable "sns_topic_arns" {
  description = "ARNs de los SNS Topics (opcional)"
  type        = list(string)
  default     = null
}

variable "sqs_queue_arns" {
  description = "ARNs de las SQS Queues (opcional)"
  type        = list(string)
  default     = null
}

