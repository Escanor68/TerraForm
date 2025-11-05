variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "cors_origins" {
  description = "Orígenes permitidos para CORS en API Gateway"
  type        = list(string)
  default     = ["*"]
}

variable "enable_sns_encryption" {
  description = "Habilitar encriptación para SNS Topics"
  type        = bool
  default     = true
}

variable "enable_sqs_encryption" {
  description = "Habilitar encriptación para SQS Queues"
  type        = bool
  default     = true
}

variable "load_balancer_dns" {
  description = "DNS name del Load Balancer"
  type        = string
}

variable "load_balancer_arn" {
  description = "ARN del Load Balancer"
  type        = string
}

