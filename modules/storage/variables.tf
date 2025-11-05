variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
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

