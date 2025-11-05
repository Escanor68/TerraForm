output "parameter_store_dev_arns" {
  description = "ARNs de los parámetros de Parameter Store para dev"
  value       = { for k, v in aws_ssm_parameter.dev_env_vars : k => v.arn }
}

output "parameter_store_preprod_arns" {
  description = "ARNs de los parámetros de Parameter Store para preprod"
  value       = { for k, v in aws_ssm_parameter.preprod_env_vars : k => v.arn }
}

output "parameter_store_prod_arns" {
  description = "ARNs de los parámetros de Parameter Store para prod"
  value       = { for k, v in aws_ssm_parameter.prod_env_vars : k => v.arn }
}

output "parameter_store_dev_names" {
  description = "Nombres de los parámetros de Parameter Store para dev"
  value       = { for k, v in aws_ssm_parameter.dev_env_vars : k => v.name }
}

output "parameter_store_preprod_names" {
  description = "Nombres de los parámetros de Parameter Store para preprod"
  value       = { for k, v in aws_ssm_parameter.preprod_env_vars : k => v.name }
}

output "parameter_store_prod_names" {
  description = "Nombres de los parámetros de Parameter Store para prod"
  value       = { for k, v in aws_ssm_parameter.prod_env_vars : k => v.name }
}

