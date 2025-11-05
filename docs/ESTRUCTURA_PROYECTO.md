# Estructura del Proyecto Terraform

> **⚠️ NOTA**: Este documento es de referencia. Para la estructura actualizada, ver el README principal en la raíz del proyecto.

Este proyecto está organizado en módulos para facilitar el mantenimiento y la escalabilidad.

## Estructura de Carpetas

```
.
├── main.tf                          # Archivo principal - Orquesta todos los módulos
├── variables.tf                     # Variables globales
├── outputs.tf                       # Outputs globales
├── terraform.tfvars.example         # Ejemplo de configuración
├── .gitignore                       # Archivos a ignorar en Git
│
├── modules/                         # Módulos de Terraform
│   ├── networking/                  # VPC, Subnets, IGW, NAT
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── security/                    # Security Groups e IAM
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/                     # EC2, Auto Scaling, Load Balancer
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ci-cd/                       # CodeCommit, CodeBuild, CodePipeline
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── messaging/                   # API Gateway, SNS, SQS
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── storage/                     # Parameter Store, Secrets Manager
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── docs/                            # Documentación
│   ├── README.md                    # Documentación principal
│   ├── VARIABLES_DE_ENTORNO.md     # Guía de variables de entorno
│   ├── COMUNICACION_SERVICIOS.md   # Guía de comunicación entre servicios
│   └── EKS_VS_EC2.md               # Comparación EKS vs EC2
│
└── ejemplos/                        # Ejemplos de código Node.js
    ├── ejemplo-nodejs-mysql.js
    ├── ejemplo-nodejs-api-gateway.js
    └── ejemplo-nodejs-sns-sqs.js
```

## Flujo de Ejecución

1. **main.tf** - Punto de entrada principal
   - Configura provider AWS
   - Llama a todos los módulos en orden
   - Define las dependencias entre módulos

2. **Módulos** - Cada módulo es independiente
   - Recibe variables de entrada
   - Crea recursos específicos
   - Expone outputs para otros módulos

3. **Variables** - Configuración centralizada
   - Todas las variables en `variables.tf`
   - Valores por defecto en `terraform.tfvars`

4. **Outputs** - Resultados consolidados
   - Todos los outputs importantes en `outputs.tf`

## Ventajas de esta Estructura

✅ **Modularidad**: Cada componente es independiente
✅ **Reutilización**: Módulos pueden reutilizarse en otros proyectos
✅ **Mantenibilidad**: Fácil encontrar y modificar recursos
✅ **Escalabilidad**: Agregar nuevos módulos es simple
✅ **Testing**: Cada módulo puede probarse independientemente

## Uso

```bash
# Inicializar Terraform
terraform init

# Verificar plan
terraform plan

# Aplicar cambios
terraform apply

# Ver outputs
terraform output
```

