variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para las subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks para las subnets públicas"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks para las subnets privadas"
  type        = list(string)
}

