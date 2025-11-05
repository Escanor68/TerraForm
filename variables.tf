variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "mi-proyecto"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para las subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks para las subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks para las subnets privadas"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "codecommit_repo_name" {
  description = "Nombre del repositorio CodeCommit"
  type        = string
  default     = "mi-repositorio"
}

variable "codebuild_project_name" {
  description = "Nombre del proyecto CodeBuild"
  type        = string
  default     = "mi-codebuild"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Número mínimo de instancias en el Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Número máximo de instancias en el Auto Scaling Group"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Número deseado de instancias en el Auto Scaling Group"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "Nombre de la clave SSH para acceder a las instancias EC2"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitidos para acceso HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_pipelines" {
  description = "Habilitar pipelines de CI/CD para todas las ramas"
  type        = bool
  default     = true
}

variable "artifacts_retention_days" {
  description = "Días de retención para artifacts en S3"
  type        = number
  default     = 30
}

variable "codebuild_environment_variables" {
  description = "Variables de entorno para CodeBuild (no sensibles). Formato: {env_name: {key: value}}"
  type = map(map(string))
  default = {
    dev = {}
    preprod = {}
    prod = {}
  }
}

variable "use_parameter_store" {
  description = "Habilitar uso de Parameter Store para variables sensibles"
  type        = bool
  default     = true
}

variable "use_secrets_manager" {
  description = "Habilitar uso de Secrets Manager para secretos complejos"
  type        = bool
  default     = false
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

