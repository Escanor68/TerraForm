# AWS Systems Manager Parameter Store - Variables de entorno por ambiente
# Este archivo permite definir variables sensibles que se almacenan de forma segura

# Ejemplo de parámetros para DEV
resource "aws_ssm_parameter" "dev_env_vars" {
  for_each = var.use_parameter_store ? {
    # Ejemplo de variables para conexión MySQL
    # "MYSQL_PASSWORD"      = "dev-password-123"
    # "MYSQL_DATABASE_URL"  = "mysql://devuser:dev-password-123@dev-mysql-db.xxxxx.us-east-1.rds.amazonaws.com:3306/dev_database"
    
    # Otros ejemplos
    # "API_KEY"             = "dev-api-key-12345"
    # "JWT_SECRET"          = "dev-jwt-secret-key"
    # "REDIS_URL"           = "redis://dev-redis:6379"
  } : {}

  name  = "/${var.project_name}/dev/${each.key}"
  type  = "SecureString"
  value = each.value

  tags = {
    Name        = "${var.project_name}-dev-${each.key}"
    Environment = "dev"
    Project     = var.project_name
  }
}

# Ejemplo de parámetros para PREPROD
resource "aws_ssm_parameter" "preprod_env_vars" {
  for_each = var.use_parameter_store ? {
    # Ejemplo de variables para conexión MySQL
    # "MYSQL_PASSWORD"      = "preprod-password-456"
    # "MYSQL_DATABASE_URL"  = "mysql://preproduser:preprod-password-456@preprod-mysql-db.xxxxx.us-east-1.rds.amazonaws.com:3306/preprod_database"
    
    # Otros ejemplos
    # "API_KEY"             = "preprod-api-key-12345"
    # "JWT_SECRET"          = "preprod-jwt-secret-key"
    # "REDIS_URL"           = "redis://preprod-redis:6379"
  } : {}

  name  = "/${var.project_name}/preprod/${each.key}"
  type  = "SecureString"
  value = each.value

  tags = {
    Name        = "${var.project_name}-preprod-${each.key}"
    Environment = "preprod"
    Project     = var.project_name
  }
}

# Ejemplo de parámetros para PROD
resource "aws_ssm_parameter" "prod_env_vars" {
  for_each = var.use_parameter_store ? {
    # Ejemplo de variables para conexión MySQL
    # "MYSQL_PASSWORD"      = "prod-password-super-segura-789"
    # "MYSQL_DATABASE_URL"  = "mysql://produser:prod-password-super-segura-789@prod-mysql-db.xxxxx.us-east-1.rds.amazonaws.com:3306/prod_database"
    
    # Otros ejemplos
    # "API_KEY"             = "prod-api-key-12345"
    # "JWT_SECRET"          = "prod-jwt-secret-key-ultra-segura"
    # "REDIS_URL"           = "redis://prod-redis:6379"
  } : {}

  name  = "/${var.project_name}/prod/${each.key}"
  type  = "SecureString"
  value = each.value

  tags = {
    Name        = "${var.project_name}-prod-${each.key}"
    Environment = "prod"
    Project     = var.project_name
  }
}

# Secrets Manager - Para secretos más complejos (opcional)
# Descomenta y ajusta según tus necesidades
# resource "aws_secretsmanager_secret" "dev_secrets" {
#   count = var.use_secrets_manager ? 1 : 0
#   name  = "${var.project_name}/dev/secrets"
#
#   description = "Secretos para el entorno DEV"
#
#   tags = {
#     Name        = "${var.project_name}-dev-secrets"
#     Environment = "dev"
#     Project     = var.project_name
#   }
# }
#
# resource "aws_secretsmanager_secret_version" "dev_secrets" {
#   count     = var.use_secrets_manager ? 1 : 0
#   secret_id = aws_secretsmanager_secret.dev_secrets[0].id
#
#   secret_string = jsonencode({
#     database_password = "dev-password-here"
#     api_secret_key    = "dev-secret-key-here"
#   })
# }

