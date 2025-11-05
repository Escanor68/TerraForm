# Guía de Variables de Entorno

Este documento explica cómo configurar y usar variables de entorno en los proyectos CodeBuild para cada entorno (dev, preprod, prod).

## Tipos de Variables de Entorno

### 1. Variables No Sensibles (terraform.tfvars)

Estas variables se definen directamente en `terraform.tfvars` y se almacenan en el proyecto CodeBuild. **Úsala solo para valores que no son secretos**.

**Ejemplo en `terraform.tfvars`:**

```hcl
codebuild_environment_variables = {
  dev = {
    "NODE_ENV"       = "development"
    "LOG_LEVEL"      = "debug"
    "FEATURE_FLAG_X" = "enabled"
    "API_TIMEOUT"    = "5000"
  }
  preprod = {
    "NODE_ENV"       = "staging"
    "LOG_LEVEL"      = "info"
    "FEATURE_FLAG_X" = "enabled"
    "API_TIMEOUT"    = "3000"
  }
  prod = {
    "NODE_ENV"       = "production"
    "LOG_LEVEL"      = "error"
    "FEATURE_FLAG_X" = "disabled"
    "API_TIMEOUT"    = "2000"
  }
}
```

### 2. Variables Sensibles (Parameter Store)

Para valores sensibles como contraseñas, API keys, tokens, etc., usa **AWS Systems Manager Parameter Store**.

#### Opción A: Definir en Terraform (parameter_store.tf)

Edita el archivo `parameter_store.tf` y descomenta/agrega los parámetros que necesites:

```hcl
resource "aws_ssm_parameter" "dev_env_vars" {
  for_each = {
    "DATABASE_URL" = "mysql://dev-db:3306/mydb"
    "API_KEY"      = "dev-api-key-12345"
    "REDIS_URL"    = "redis://dev-redis:6379"
  }

  name  = "/${var.project_name}/dev/${each.key}"
  type  = "SecureString"
  value = each.value
  # ... resto de la configuración
}
```

**⚠️ IMPORTANTE**: Si usas valores sensibles reales, considera usar variables de Terraform o fuentes externas en lugar de hardcodearlos.

#### Opción B: Crear manualmente en AWS Console

1. Ve a **AWS Systems Manager** → **Parameter Store**
2. Crea un parámetro con el formato: `/{project_name}/{environment}/{variable_name}`
   - Ejemplo: `/mi-proyecto/dev/DATABASE_PASSWORD`
3. Selecciona tipo **SecureString**
4. Ingresa el valor
5. El proyecto CodeBuild podrá acceder a él automáticamente

#### Opción C: Usar AWS CLI

```bash
# Crear parámetro para DEV
aws ssm put-parameter \
  --name "/mi-proyecto/dev/DATABASE_PASSWORD" \
  --value "mi-password-segura" \
  --type "SecureString" \
  --region us-east-1

# Crear parámetro para PROD
aws ssm put-parameter \
  --name "/mi-proyecto/prod/DATABASE_PASSWORD" \
  --value "mi-password-prod-segura" \
  --type "SecureString" \
  --region us-east-1
```

### 3. Secretos Complejos (Secrets Manager)

Para secretos más complejos (JSON, múltiples valores, etc.), usa **AWS Secrets Manager**.

#### Habilitar Secrets Manager

1. En `terraform.tfvars`, establece:
   ```hcl
   use_secrets_manager = true
   ```

2. En `parameter_store.tf`, descomenta y configura los recursos de Secrets Manager:

```hcl
resource "aws_secretsmanager_secret" "dev_secrets" {
  name        = "${var.project_name}/dev/secrets"
  description = "Secretos para el entorno DEV"
}

resource "aws_secretsmanager_secret_version" "dev_secrets" {
  secret_id = aws_secretsmanager_secret.dev_secrets[0].id
  
  secret_string = jsonencode({
    database_password = "dev-password-here"
    api_secret_key    = "dev-secret-key-here"
    jwt_secret        = "dev-jwt-secret"
  })
}
```

3. En `codebuild.tf`, descomenta el bloque de variables de Secrets Manager.

## Uso en buildspec.yml

Las variables de entorno están disponibles automáticamente en tu `buildspec.yml`:

```yaml
version: 0.2

phases:
  build:
    commands:
      # Variables no sensibles están disponibles directamente
      - echo "NODE_ENV es $NODE_ENV"
      - echo "LOG_LEVEL es $LOG_LEVEL"
      
      # Variables de Parameter Store también están disponibles
      - echo "Conectando a base de datos: $DATABASE_URL"
      - echo "API Key configurada: ${API_KEY:0:5}..." # Solo mostrar primeros caracteres
      
      # Variables de Secrets Manager (si usas JSON)
      - echo "Secretos cargados desde Secrets Manager"
      
      # Tu código de build aquí
      - npm install
      - npm run build
```

## Estructura de Nombres

### Parameter Store

Los parámetros deben seguir este formato:
```
/{project_name}/{environment}/{variable_name}
```

Ejemplos:
- `/mi-proyecto/dev/DATABASE_URL`
- `/mi-proyecto/preprod/API_KEY`
- `/mi-proyecto/prod/REDIS_URL`

### Secrets Manager

Los secretos deben seguir este formato:
```
{project_name}/{environment}/secrets
```

Ejemplos:
- `mi-proyecto/dev/secrets`
- `mi-proyecto/preprod/secrets`
- `mi-proyecto/prod/secrets`

## Buenas Prácticas

1. **Nunca hardcodees secretos** en archivos de Terraform que se suban a Git
2. **Usa Parameter Store** para valores simples y sensibles
3. **Usa Secrets Manager** para objetos JSON complejos o múltiples secretos relacionados
4. **Separa por entorno**: cada entorno (dev, preprod, prod) debe tener sus propios valores
5. **Rota los secretos** periódicamente, especialmente en producción
6. **Usa encriptación**: Parameter Store y Secrets Manager encriptan automáticamente los valores

## Ejemplo Completo: Configuración MySQL

### Variables No Sensibles (terraform.tfvars)

Define las variables que no son secretas directamente en `terraform.tfvars`:

```hcl
codebuild_environment_variables = {
  dev = {
    "MYSQL_HOST"              = "dev-mysql-db.xxxxx.us-east-1.rds.amazonaws.com"
    "MYSQL_PORT"              = "3306"
    "MYSQL_DATABASE"          = "dev_database"
    "MYSQL_USER"              = "devuser"
    "MYSQL_POOL_SIZE"         = "10"
    "MYSQL_CONNECTION_TIMEOUT" = "5000"
    "MYSQL_CHARSET"           = "utf8mb4"
  }
  prod = {
    "MYSQL_HOST"              = "prod-mysql-db.xxxxx.us-east-1.rds.amazonaws.com"
    "MYSQL_PORT"              = "3306"
    "MYSQL_DATABASE"          = "prod_database"
    "MYSQL_USER"              = "produser"
    "MYSQL_POOL_SIZE"         = "50"
    "MYSQL_CONNECTION_TIMEOUT" = "2000"
    "MYSQL_CHARSET"           = "utf8mb4"
  }
}
```

### Variables Sensibles (Parameter Store)

Almacena la contraseña y URL completa en Parameter Store:

#### Opción 1: Solo la contraseña (recomendado)

En `parameter_store.tf`:
```hcl
resource "aws_ssm_parameter" "dev_env_vars" {
  for_each = {
    "MYSQL_PASSWORD" = "dev-password-123"
  }
  # ... resto de configuración
}
```

En tu código/buildspec.yml, construyes la URL:
```bash
MYSQL_URL="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"
```

#### Opción 2: URL completa (alternativa)

En `parameter_store.tf`:
```hcl
resource "aws_ssm_parameter" "dev_env_vars" {
  for_each = {
    "MYSQL_DATABASE_URL" = "mysql://devuser:dev-password-123@dev-mysql-db.xxxxx.us-east-1.rds.amazonaws.com:3306/dev_database"
  }
  # ... resto de configuración
}
```

#### Crear con AWS CLI

```bash
# Crear contraseña para DEV
aws ssm put-parameter \
  --name "/mi-proyecto/dev/MYSQL_PASSWORD" \
  --value "dev-password-123" \
  --type "SecureString" \
  --region us-east-1

# Crear contraseña para PROD
aws ssm put-parameter \
  --name "/mi-proyecto/prod/MYSQL_PASSWORD" \
  --value "prod-password-super-segura-789" \
  --type "SecureString" \
  --region us-east-1
```

### Uso en buildspec.yml

```yaml
version: 0.2

phases:
  build:
    commands:
      # Construir URL de conexión MySQL (si usas variables separadas)
      - export MYSQL_URL="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"
      
      # O usar directamente si tienes MYSQL_DATABASE_URL
      - echo "Conectando a MySQL: ${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"
      
      # Ejemplo de uso con Node.js
      - npm install
      - npm run build
      
      # Ejemplo de uso con Python
      # - pip install -r requirements.txt
      # - python manage.py migrate
```

### Ejemplo de código de aplicación

#### Node.js (con mysql2)

```javascript
const mysql = require('mysql2/promise');

const connection = mysql.createPool({
  host: process.env.MYSQL_HOST,
  port: process.env.MYSQL_PORT,
  database: process.env.MYSQL_DATABASE,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  waitForConnections: true,
  connectionLimit: parseInt(process.env.MYSQL_POOL_SIZE || '10'),
  queueLimit: 0
});
```

#### Python (con mysql-connector-python)

```python
import mysql.connector
import os

connection = mysql.connector.connect(
    host=os.getenv('MYSQL_HOST'),
    port=int(os.getenv('MYSQL_PORT', 3306)),
    database=os.getenv('MYSQL_DATABASE'),
    user=os.getenv('MYSQL_USER'),
    password=os.getenv('MYSQL_PASSWORD'),
    pool_size=int(os.getenv('MYSQL_POOL_SIZE', 10))
)
```

## Ejemplos Comunes

### Base de Datos

```bash
# Crear parámetro de conexión a base de datos MySQL
aws ssm put-parameter \
  --name "/mi-proyecto/dev/MYSQL_PASSWORD" \
  --value "mi-password-segura" \
  --type "SecureString" \
  --region us-east-1
```

### API Keys

```bash
# Crear API key para servicio externo
aws ssm put-parameter \
  --name "/mi-proyecto/prod/STRIPE_API_KEY" \
  --value "sk_live_..." \
  --type "SecureString"
```

### Tokens JWT

```bash
# Crear secreto JWT
aws ssm put-parameter \
  --name "/mi-proyecto/prod/JWT_SECRET" \
  --value "tu-secreto-jwt-super-seguro" \
  --type "SecureString"
```

### Configuración Compleja (Secrets Manager)

```bash
# Crear secreto con múltiples valores
aws secretsmanager create-secret \
  --name "mi-proyecto/prod/secrets" \
  --secret-string '{
    "database_url": "postgresql://...",
    "redis_url": "redis://...",
    "jwt_secret": "...",
    "api_keys": {
      "stripe": "...",
      "sendgrid": "..."
    }
  }'
```

## Verificar Variables

Puedes verificar que las variables estén disponibles en tu build:

```yaml
phases:
  pre_build:
    commands:
      - echo "=== Variables de Entorno ==="
      - env | grep -E "(NODE_ENV|DATABASE|API|REDIS)" | sort
```

## Troubleshooting

### La variable no está disponible en el build

1. Verifica que el parámetro existe en Parameter Store:
   ```bash
   aws ssm get-parameter --name "/mi-proyecto/dev/VARIABLE_NAME"
   ```

2. Verifica los permisos IAM del rol de CodeBuild (debe tener acceso a SSM)

3. Verifica que el nombre del parámetro coincida con el formato esperado

4. Revisa los logs de CloudWatch para ver errores específicos

### Error de permisos

Si CodeBuild no puede acceder a Parameter Store o Secrets Manager:

1. Verifica que el rol IAM `codebuild` tenga las políticas correctas
2. Las políticas están en `iam.tf` y deben incluir:
   - `ssm:GetParameters`
   - `ssm:GetParameter`
   - `secretsmanager:GetSecretValue`

## Referencias

- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [CodeBuild Environment Variables](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-env-vars.html)

