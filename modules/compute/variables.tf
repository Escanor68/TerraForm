variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID del Security Group del ALB"
  type        = string
}

variable "ec2_security_group_id" {
  description = "ID del Security Group de EC2"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "Nombre del Instance Profile para EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre de la clave SSH para acceder a las instancias EC2"
  type        = string
  default     = ""
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

