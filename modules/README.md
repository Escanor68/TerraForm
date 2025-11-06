# Infraestructura AWS con Terraform - Estructura Modular

Este proyecto proporciona una infraestructura completa de AWS para aplicaciones Node.js usando Terraform, organizada en módulos reutilizables.

## 📁 Estructura del Proyecto

```
.
├── main.tf                    # Configuración principal y llamadas a módulos
├── variables.tf               # Variables de entrada del proyecto
├── outputs.tf                 # Outputs del proyecto
├── terraform.tfvars.example   # Ejemplo de valores de variables
│
├── modules/                   # Módulos de Terraform
│   ├── networking/            # VPC, Subnets, Internet Gateway, NAT Gateway
│   ├── security/              # Security Groups, IAM Roles y Policies
│   ├── compute/               # EC2, Auto Scaling Group, Application Load Balancer
│   ├── ci-cd/                 # CodeCommit, CodeBuild, CodePipeline
│   ├── messaging/             # API Gateway, SNS Topics, SQS Queues
│   └── storage/               # Parameter Store, Secrets Manager
│
├── docs/                      # Documentación
│   ├── README.md              # Documentación principal (este archivo)
│   ├── VARIABLES_DE_ENTORNO.md
│   ├── EKS_VS_EC2.md
│   └── ...
│
└── ejemplos/                  # Ejemplos de código
    ├── buildspec.yml.example
    ├── ejemplo-nodejs-api-gateway.js
    └── ejemplo-nodejs-sns-sqs.js
```

## 🏗️ Módulos

### 1. **Networking** (`modules/networking/`)
- VPC con CIDR configurable
- Subnets públicas y privadas en múltiples AZs
- Internet Gateway
- NAT Gateway para subnets privadas
- Route Tables

### 2. **Security** (`modules/security/`)
- Security Groups para ALB y EC2
- IAM Role y Instance Profile para EC2
- Permisos para CloudWatch Logs, S3, SNS y SQS

### 3. **Compute** (`modules/compute/`)
- Application Load Balancer (ALB)
- Target Group con health checks
- Launch Template para EC2
- Auto Scaling Group con políticas de escalado
- CloudWatch Alarms para CPU

### 4. **CI/CD** (`modules/ci-cd/`)
- Repositorio CodeCommit
- Proyectos CodeBuild para `dev`, `preprod` y `prod`
- Pipelines de CodePipeline para cada entorno
- S3 Bucket para artifacts con versionado y lifecycle
- IAM Roles y Policies para CodeBuild y CodePipeline

### 5. **Messaging** (`modules/messaging/`)
- API Gateway (HTTP API) con stages por entorno
- SNS Topics: `events`, `notifications`, `data_processing`
- SQS Queues: `events_queue`, `notifications_queue`, `data_processing_queue`, `data_processing_dlq`
- Integración automática SNS → SQS
- Encriptación opcional con KMS

### 6. **Storage** (`modules/storage/`)
- Parameter Store para variables sensibles por entorno
- Secrets Manager (opcional) para secretos complejos

## 🚀 Inicio Rápido

### 1. Configurar Variables

Copia el archivo de ejemplo y ajusta los valores:

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

# CodeCommit
codecommit_repo_name = "mi-repositorio"

# Instancias
instance_type = "t3.micro"
min_size      = 2
max_size      = 4
desired_capacity = 2
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Revisar Plan

```bash
terraform plan
```

### 4. Aplicar Configuración

```bash
terraform apply
```

## 📝 Variables Principales

| Variable | Descripción | Default |
|----------|-------------|---------|
| `project_name` | Nombre del proyecto | - |
| `aws_region` | Región de AWS | `us-east-1` |
| `vpc_cidr` | CIDR de la VPC | `10.0.0.0/16` |
| `codecommit_repo_name` | Nombre del repositorio CodeCommit | - |
| `instance_type` | Tipo de instancia EC2 | `t3.micro` |
| `min_size` | Mínimo de instancias en ASG | `2` |
| `max_size` | Máximo de instancias en ASG | `4` |
| `enable_pipelines` | Habilitar pipelines CI/CD | `true` |
| `use_parameter_store` | Usar Parameter Store | `true` |
| `cors_origins` | Orígenes CORS permitidos | `["*"]` |

Ver `variables.tf` para la lista completa.

## 🔄 CI/CD

El proyecto está configurado para tres entornos:

- **dev**: Desarrollo
- **preprod**: Pre-producción
- **prod**: Producción

Cada entorno tiene su propio:
- Proyecto CodeBuild
- Pipeline de CodePipeline
- Stage de API Gateway

### Flujo de Trabajo

1. **Push a `dev`** → Trigger automático del pipeline de dev
2. **Push a `preprod`** → Trigger automático del pipeline de preprod
3. **Push a `prod`** → Trigger automático del pipeline de prod (con 3 aprobaciones manuales requeridas)

### 🔐 Aprobaciones para Producción

El módulo CI/CD implementa **tres niveles de control** para producción:

#### 1. Validación de Mensajes de Commit (Conventional Commits)
- Valida automáticamente que los commits sigan el formato Conventional Commits
- Tipos permitidos: feat, fix, perf, build, ci, docs, refactor, style, test
- Se ejecuta mediante Lambda function cuando se crea/actualiza un PR
- Variables: `validate_commit_messages`

#### 2. Aprobaciones de PR (CodeCommit)
- Requiere **3 aprobaciones** antes de mergear PRs al branch `prod`
- Configurado mediante Approval Rule Templates
- Variables: `require_prod_pr_approvals`, `prod_approvers_arn`

#### 3. Aprobaciones Manuales en Pipeline (CodePipeline)
- Requiere **3 aprobaciones manuales** antes del despliegue
- Flujo: Source → Approval-1 → Approval-2 → Approval-3 → Build
- Variables: `require_prod_approvals`, `prod_approval_sns_topic_arn`

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
  post_build:
    commands:
      - echo "Build completado"
```

Ver `ejemplos/buildspec.yml.example` para más detalles.

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
  # ...
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
  # ...
}
```

Ver `docs/VARIABLES_DE_ENTORNO.md` para más información.

## 🌐 Comunicación entre Servicios

### Frontend ↔ Backend

Usa **API Gateway**:

```javascript
const API_URL = 'https://{api-id}.execute-api.{region}.amazonaws.com/{env}';
```

### Backend ↔ Backend (Asíncrono)

Usa **SNS** (Pub/Sub) o **SQS** (Colas):

```javascript
// Publicar a SNS
await sns.publish({
  TopicArn: process.env.SNS_EVENTS_TOPIC_ARN,
  Message: JSON.stringify({ event: 'user.created', data: {...} })
}).promise();

// Consumir de SQS
const messages = await sqs.receiveMessage({
  QueueUrl: process.env.SQS_EVENTS_QUEUE_URL
}).promise();
```

Ver `ejemplos/ejemplo-nodejs-api-gateway.js` y `ejemplos/ejemplo-nodejs-sns-sqs.js` para ejemplos completos.

## 📊 Outputs

Después de aplicar Terraform, puedes obtener:

- **VPC y Networking**: IDs de VPC, subnets
- **Load Balancer**: DNS name, ARN
- **CodeCommit**: URL del repositorio
- **CodeBuild**: Nombres de proyectos por entorno
- **API Gateway**: URLs por entorno
- **SNS/SQS**: ARNs y URLs de topics y queues

```bash
terraform output
```

## 🔧 Mantenimiento

### Actualizar un Módulo

Los módulos están en `modules/`. Para modificar:

1. Edita los archivos del módulo correspondiente
2. Ejecuta `terraform plan` para revisar cambios
3. Ejecuta `terraform apply` para aplicar

### Añadir Nuevos Recursos

Crea recursos adicionales en `main.tf` o en el módulo correspondiente según la lógica.

## 📚 Documentación Adicional

- `docs/VARIABLES_DE_ENTORNO.md` - Guía completa de variables de entorno
- `docs/EKS_VS_EC2.md` - Comparación entre EKS y EC2/ASG
- `docs/ESTRUCTURA_PROYECTO.md` - Explicación detallada de la estructura
- `docs/MIGRACION_MODULAR.md` - Guía de migración a estructura modular

## 🛠️ Requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Permisos adecuados en AWS

## 📄 Licencia

Este proyecto es un template de referencia para infraestructura AWS.

## 🤝 Contribuciones

Este es un proyecto de referencia. Siéntete libre de adaptarlo a tus necesidades.

---

**Nota**: Recuerda revisar y ajustar los valores por defecto según tus necesidades de seguridad y compliance.

