# Infraestructura AWS con Terraform - Estructura Modular

Este proyecto proporciona una **infraestructura completa y modular de AWS** para aplicaciones Node.js usando Terraform, organizada en módulos reutilizables y mantenibles.

## 🎯 Características Principales

- ✅ **Arquitectura Modular**: 6 módulos independientes y reutilizables
- ✅ **CI/CD Completo**: CodeCommit, CodeBuild y CodePipeline para 3 entornos (dev, preprod, prod)
- ✅ **Auto Scaling**: Application Load Balancer con Auto Scaling Group
- ✅ **Comunicación entre Servicios**: API Gateway, SNS y SQS
- ✅ **Seguridad**: Parameter Store para variables sensibles, IAM roles configurados
- ✅ **Multi-Entorno**: Configuración separada para dev, preprod y prod
- ✅ **Listo para Node.js**: Configuraciones optimizadas para aplicaciones Node.js

## 📁 Estructura del Proyecto

```
.
├── main.tf                    # Configuración principal y orquestación de módulos
├── variables.tf               # Variables de entrada globales
├── outputs.tf                 # Outputs del proyecto
├── terraform.tfvars.example   # Ejemplo de valores de variables
├── .gitignore                 # Configuración de Git
│
├── modules/                   # Módulos de Terraform
│   ├── networking/            # VPC, Subnets, Internet Gateway, NAT Gateway
│   ├── security/              # Security Groups, IAM Roles y Policies
│   ├── compute/               # EC2, Auto Scaling Group, Application Load Balancer
│   ├── ci-cd/                 # CodeCommit, CodeBuild, CodePipeline
│   ├── messaging/             # API Gateway, SNS Topics, SQS Queues
│   └── storage/               # Parameter Store, Secrets Manager
│
├── docs/                      # Documentación técnica completa
│   ├── README.md              # Índice de documentación
│   ├── VARIABLES_DE_ENTORNO.md
│   ├── COMUNICACION_SERVICIOS.md
│   ├── EKS_VS_EC2.md
│   └── RESUMEN_REVISION.md
│
└── ejemplos/                  # Ejemplos de código
    ├── buildspec.yml.example
    ├── ejemplo-nodejs-api-gateway.js
    ├── ejemplo-nodejs-mysql.js
    └── ejemplo-nodejs-sns-sqs.js
```

## 🏗️ Módulos del Proyecto

### 1. **Networking** (`modules/networking/`)
Infraestructura de red completa:
- VPC con CIDR configurable
- Subnets públicas y privadas en múltiples Availability Zones
- Internet Gateway para acceso público
- NAT Gateway para subnets privadas
- Route Tables configuradas

### 2. **Security** (`modules/security/`)
Seguridad y permisos:
- Security Groups para ALB y EC2
- IAM Role y Instance Profile para EC2
- Permisos para CloudWatch Logs, S3, SNS y SQS
- Políticas de acceso configuradas

### 3. **Compute** (`modules/compute/`)
Recursos de cómputo:
- Application Load Balancer (ALB) con health checks
- Target Group configurado
- Launch Template para instancias EC2
- Auto Scaling Group con políticas de escalado automático
- CloudWatch Alarms para monitoreo de CPU

### 4. **CI/CD** (`modules/ci-cd/`)
Pipeline de integración y despliegue continuo:
- Repositorio CodeCommit
- Proyectos CodeBuild para `dev`, `preprod` y `prod`
- Pipelines de CodePipeline para cada entorno
- S3 Bucket para artifacts con versionado y lifecycle
- IAM Roles y Policies para CodeBuild y CodePipeline
- CloudWatch Log Groups por entorno

### 5. **Messaging** (`modules/messaging/`)
Comunicación entre servicios:
- API Gateway (HTTP API) con stages por entorno
- SNS Topics: `events`, `notifications`, `data_processing`
- SQS Queues: `events_queue`, `notifications_queue`, `data_processing_queue`, `data_processing_dlq`
- Integración automática SNS → SQS
- Encriptación opcional con KMS

### 6. **Storage** (`modules/storage/`)
Almacenamiento seguro de configuración:
- Parameter Store para variables sensibles por entorno
- Secrets Manager (opcional) para secretos complejos
- Separación por entorno (dev, preprod, prod)

## 🚀 Inicio Rápido

### Prerrequisitos

- Terraform >= 1.0
- AWS CLI configurado con credenciales
- Permisos adecuados en AWS (IAM, EC2, VPC, CodeCommit, CodeBuild, etc.)

### 1. Configurar Variables

Copia el archivo de ejemplo y ajusta los valores según tu proyecto:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:

```hcl
project_name = "mi-proyecto"
aws_region   = "us-east-1"
environment  = "dev"

# VPC
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# CodeCommit
codecommit_repo_name = "mi-repositorio"

# Instancias EC2
instance_type = "t3.micro"
min_size      = 2
max_size      = 4
desired_capacity = 2
key_name      = "mi-clave-ssh"  # Opcional

# CI/CD
enable_pipelines = true
artifacts_retention_days = 30

# Variables de entorno (ver terraform.tfvars.example para más ejemplos)
codebuild_environment_variables = {
  dev = {
    NODE_ENV  = "development"
    LOG_LEVEL = "debug"
  }
}
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Revisar Plan de Ejecución

```bash
terraform plan
```

Revisa cuidadosamente los recursos que se crearán.

### 4. Aplicar Configuración

```bash
terraform apply
```

Confirma con `yes` cuando se solicite.

## 📝 Variables Principales

| Variable | Descripción | Default | Requerido |
|----------|-------------|---------|-----------|
| `project_name` | Nombre del proyecto | `"mi-proyecto"` | No |
| `aws_region` | Región de AWS | `"us-east-1"` | No |
| `environment` | Entorno de despliegue | `"dev"` | No |
| `vpc_cidr` | CIDR block de la VPC | `"10.0.0.0/16"` | No |
| `codecommit_repo_name` | Nombre del repositorio CodeCommit | `"mi-repositorio"` | No |
| `instance_type` | Tipo de instancia EC2 | `"t3.micro"` | No |
| `min_size` | Mínimo de instancias en ASG | `2` | No |
| `max_size` | Máximo de instancias en ASG | `4` | No |
| `enable_pipelines` | Habilitar pipelines CI/CD | `true` | No |
| `use_parameter_store` | Usar Parameter Store | `true` | No |
| `cors_origins` | Orígenes CORS permitidos | `["*"]` | No |

Ver `variables.tf` para la lista completa de variables.

## 🔄 CI/CD Pipeline

El proyecto está configurado para **tres entornos** con pipelines independientes:

### Entornos

- **dev**: Desarrollo
- **preprod**: Pre-producción
- **prod**: Producción

### Flujo de Trabajo

1. **Push a `dev`** → Trigger automático del pipeline de dev
2. **Push a `preprod`** → Trigger automático del pipeline de preprod
3. **Push a `prod`** → Trigger automático del pipeline de prod (con 3 aprobaciones manuales requeridas)

Cada entorno tiene su propio:
- Proyecto CodeBuild
- Pipeline de CodePipeline
- Stage de API Gateway
- Variables de entorno (Parameter Store)

### 🔐 Aprobaciones para Producción

El proyecto tiene **dos niveles de aprobación** para garantizar la calidad del código en producción:

#### 1. Aprobaciones de Pull Request (CodeCommit)

Antes de que un PR pueda ser mergeado al branch `prod`, se requieren **3 aprobaciones de desarrolladores**:

- Se configura mediante **Approval Rule Templates** de CodeCommit
- Solo aplica a PRs dirigidas al branch `prod`
- Los desarrolladores deben aprobar el PR en CodeCommit antes de poder hacer merge
- Por defecto, cualquier usuario con permisos puede aprobar (puedes restringir con `prod_approvers_arn`)

**Configuración:**
- `require_prod_pr_approvals = true` (default) - Habilita las aprobaciones de PR
- `prod_approvers_arn` (opcional) - Lista de ARNs de usuarios/grupos IAM que pueden aprobar

#### 2. Aprobaciones Manuales en el Pipeline (CodePipeline)

Después de que el código se mergea a `prod`, el pipeline requiere **3 aprobaciones manuales** antes del despliegue:

1. **Source**: El código se obtiene del branch `prod` en CodeCommit
2. **Approval-1**: Primera aprobación manual requerida
3. **Approval-2**: Segunda aprobación manual requerida
4. **Approval-3**: Tercera aprobación manual requerida
5. **Build**: Una vez aprobadas las 3 etapas, se ejecuta el build

**Cómo aprobar en AWS Console:**
1. Ve a **CodePipeline** → Selecciona tu pipeline de producción
2. Cuando el pipeline llegue a una etapa de aprobación, verás un botón **"Review"**
3. Revisa los cambios y haz clic en **"Approve"** o **"Reject"**
4. Repite el proceso para las 3 aprobaciones

**Configuración:**
- `require_prod_approvals = true` (default) - Habilita las aprobaciones del pipeline
- `prod_approval_sns_topic_arn` (opcional) - ARN del SNS Topic para notificaciones

#### 3. Validación de Mensajes de Commit (Conventional Commits)

El proyecto valida automáticamente que todos los commits en un Pull Request sigan el formato **Conventional Commits**:

**Tipos de commit permitidos:**
- `feat`: Una nueva característica para el usuario
- `fix`: Arregla un bug que afecta al usuario
- `perf`: Cambios que mejoran el rendimiento del sitio
- `build`: Cambios en el sistema de build, tareas de despliegue o instalación
- `ci`: Cambios en la integración continua
- `docs`: Cambios en la documentación
- `refactor`: Refactorización del código como cambios de nombre de variables o funciones
- `style`: Cambios de formato, tabulaciones, espacios o puntos y coma, etc; no afectan al usuario
- `test`: Añade tests o refactoriza uno existente

**Formato requerido:** `<tipo>: <descripción>`

**Ejemplos válidos:**
- `feat: Agregar nueva funcionalidad de login`
- `fix: Corregir error en validación de formulario`
- `docs: Actualizar documentación de API`
- `refactor: Simplificar lógica de autenticación`

**Cómo funciona:**
- Cuando se crea o actualiza un Pull Request, una Lambda function valida automáticamente todos los commits
- Si algún commit no cumple con el formato, se agrega un comentario en el PR indicando los commits inválidos
- El PR permanece abierto hasta que todos los commits cumplan con el formato

**Configuración:**
- `validate_commit_messages = true` (default) - Habilita la validación de commits
- La validación se aplica a todos los branches automáticamente

### Configurar buildspec.yml

Crea un archivo `buildspec.yml` en la raíz de tu repositorio CodeCommit:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo "Instalando dependencias..."
      - npm install
  build:
    commands:
      - echo "Compilando aplicación..."
      - npm run build
      - echo "Ejecutando tests..."
      - npm test
  post_build:
    commands:
      - echo "Build completado exitosamente"
```

Ver `ejemplos/buildspec.yml.example` para más detalles y configuraciones avanzadas.

## 🔐 Variables de Entorno

### Variables No Sensibles

Define variables no sensibles en `terraform.tfvars`:

```hcl
codebuild_environment_variables = {
  dev = {
    NODE_ENV     = "development"
    LOG_LEVEL    = "debug"
    MYSQL_HOST   = "dev-db.example.com"
    MYSQL_PORT   = "3306"
    MYSQL_DB     = "dev_database"
    MYSQL_USER   = "dev_user"
  }
  preprod = {
    NODE_ENV     = "staging"
    LOG_LEVEL    = "info"
    # ...
  }
  prod = {
    NODE_ENV     = "production"
    LOG_LEVEL    = "error"
    # ...
  }
}
```

### Variables Sensibles (Parameter Store)

Define variables sensibles en `modules/storage/main.tf`:

```hcl
resource "aws_ssm_parameter" "dev_env_vars" {
  for_each = var.use_parameter_store ? {
    "MYSQL_PASSWORD" = "tu-password-segura"
    "API_KEY"        = "tu-api-key"
    "JWT_SECRET"     = "tu-jwt-secret"
  } : {}
  
  name  = "/${var.project_name}/dev/${each.key}"
  type  = "SecureString"
  value = each.value
}
```

**📚 Ver `docs/VARIABLES_DE_ENTORNO.md` para guía completa con ejemplos de Node.js y MySQL.**

## 🌐 Comunicación entre Servicios

### Frontend ↔ Backend

Usa **API Gateway** como punto de entrada:

```javascript
const API_URL = 'https://{api-id}.execute-api.{region}.amazonaws.com/{env}';

// Ejemplo de uso
fetch(`${API_URL}/api/users`, {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  }
});
```

### Backend ↔ Backend (Asíncrono)

Usa **SNS** (Pub/Sub) o **SQS** (Colas):

```javascript
// Publicar evento a SNS
const AWS = require('aws-sdk');
const sns = new AWS.SNS();

await sns.publish({
  TopicArn: process.env.SNS_EVENTS_TOPIC_ARN,
  Message: JSON.stringify({
    event: 'user.created',
    data: { userId: 123, email: 'user@example.com' }
  })
}).promise();

// Consumir mensajes de SQS
const sqs = new AWS.SQS();

const messages = await sqs.receiveMessage({
  QueueUrl: process.env.SQS_EVENTS_QUEUE_URL,
  MaxNumberOfMessages: 10
}).promise();
```

**📚 Ver `docs/COMUNICACION_SERVICIOS.md` y `ejemplos/ejemplo-nodejs-api-gateway.js` para ejemplos completos.**

## 📊 Outputs Importantes

Después de aplicar Terraform, puedes obtener información importante:

```bash
# Ver todos los outputs
terraform output

# Ver outputs específicos
terraform output load_balancer_dns
terraform output api_gateway_urls
terraform output codecommit_repo_url
```

### Outputs Principales

- **VPC y Networking**: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`
- **Load Balancer**: `load_balancer_dns`, `load_balancer_arn`
- **CodeCommit**: `codecommit_repo_url`, `codecommit_repo_arn`
- **CodeBuild**: `codebuild_project_names`, `codebuild_project_arns`
- **API Gateway**: `api_gateway_id`, `api_gateway_urls`
- **SNS/SQS**: `sns_topic_arns`, `sqs_queue_urls`

## 🔧 Mantenimiento

### Actualizar un Módulo

Los módulos están en `modules/`. Para modificar:

1. Edita los archivos del módulo correspondiente (`modules/[nombre]/main.tf`)
2. Ejecuta `terraform plan` para revisar cambios
3. Ejecuta `terraform apply` para aplicar

### Añadir Nuevos Recursos

- **Recursos relacionados con networking**: Añadir en `modules/networking/main.tf`
- **Recursos de seguridad**: Añadir en `modules/security/main.tf`
- **Recursos de cómputo**: Añadir en `modules/compute/main.tf`
- **Recursos de CI/CD**: Añadir en `modules/ci-cd/main.tf`
- **Recursos de mensajería**: Añadir en `modules/messaging/main.tf`
- **Recursos de almacenamiento**: Añadir en `modules/storage/main.tf`

### Destruir Recursos

Para eliminar toda la infraestructura:

```bash
terraform destroy
```

⚠️ **Cuidado**: Esto eliminará todos los recursos creados.

## 📚 Documentación Adicional

La documentación completa está disponible en `docs/`:

- **[Guía de Variables de Entorno](docs/VARIABLES_DE_ENTORNO.md)** - Configuración completa de variables de entorno, ejemplos de MySQL y Node.js
- **[Comunicación entre Servicios](docs/COMUNICACION_SERVICIOS.md)** - Guía detallada de API Gateway, SNS y SQS
- **[EKS vs EC2](docs/EKS_VS_EC2.md)** - Comparación entre EKS y EC2/ASG para ayudarte a decidir
- **[Resumen de Revisión](docs/RESUMEN_REVISION.md)** - Estado del proyecto y verificaciones realizadas

Ver `docs/README.md` para el índice completo de documentación.

## 🛠️ Requisitos

- **Terraform** >= 1.0
- **AWS CLI** configurado con credenciales válidas
- **Permisos AWS** adecuados:
  - EC2 (instancias, security groups, load balancers)
  - VPC (crear y gestionar VPCs, subnets, gateways)
  - IAM (crear roles y políticas)
  - CodeCommit, CodeBuild, CodePipeline
  - API Gateway, SNS, SQS
  - Systems Manager Parameter Store
  - S3 (para artifacts de CodePipeline)

## ⚠️ Consideraciones de Seguridad

- **Variables Sensibles**: Usa Parameter Store o Secrets Manager para contraseñas, API keys, tokens
- **CORS**: Ajusta `cors_origins` para permitir solo los orígenes necesarios
- **CIDR Blocks**: Restringe `allowed_cidr_blocks` a rangos específicos en producción
- **Encriptación**: Habilita `enable_sns_encryption` y `enable_sqs_encryption` para producción
- **IAM**: Revisa y ajusta las políticas IAM según el principio de menor privilegio

## 📄 Licencia

Este proyecto es un template de referencia para infraestructura AWS. Siéntete libre de adaptarlo y modificarlo según tus necesidades.

## 🤝 Contribuciones

Este es un proyecto de referencia. Si encuentras mejoras o tienes sugerencias:

1. Revisa la documentación existente
2. Ajusta el código según tus necesidades
3. Comparte mejoras con la comunidad si lo deseas

## 🆘 Soporte

Si tienes problemas:

1. Revisa la documentación en `docs/`
2. Verifica los logs de Terraform
3. Revisa los outputs con `terraform output`
4. Consulta la documentación oficial de Terraform y AWS

---

**Última actualización**: Proyecto completamente modularizado y revisado. Listo para producción.

**Nota**: Recuerda revisar y ajustar los valores por defecto según tus necesidades de seguridad, compliance y costos.
