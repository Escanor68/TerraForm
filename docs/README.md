# Documentación del Proyecto Terraform

Índice de toda la documentación técnica disponible para este proyecto.

## 📚 Documentación Disponible

### 📖 Guías Principales

#### [Variables de Entorno](VARIABLES_DE_ENTORNO.md)
Guía completa sobre cómo configurar y gestionar variables de entorno en los proyectos CodeBuild.

**Contenido:**
- Variables no sensibles en `terraform.tfvars`
- Variables sensibles en Parameter Store
- Ejemplos completos para Node.js y MySQL
- Configuración de conexión a base de datos MySQL
- Ejemplos de código Node.js y Python
- Comandos AWS CLI para gestionar parámetros

**Cuándo usar**: Cuando necesites configurar variables de entorno para tus aplicaciones, especialmente para conexiones a bases de datos y configuraciones sensibles.

---

#### [Comunicación entre Servicios](COMUNICACION_SERVICIOS.md)
Guía detallada sobre cómo configurar y usar la comunicación entre frontend, backend y servicios.

**Contenido:**
- API Gateway para comunicación Front-Back
- SNS Topics para pub/sub entre backends
- SQS Queues para procesamiento asíncrono
- Ejemplos de código Node.js
- Configuración de CORS
- Encriptación con KMS

**Cuándo usar**: Cuando necesites configurar la comunicación entre diferentes partes de tu aplicación o integrar servicios.

---

#### [EKS vs EC2](EKS_VS_EC2.md)
Comparación detallada entre EKS (Elastic Kubernetes Service) y EC2/Auto Scaling Group.

**Contenido:**
- Pros y contras de cada opción
- Comparación de costos
- Casos de uso recomendados
- Consideraciones de escalabilidad
- Guía de decisión

**Cuándo usar**: Cuando necesites decidir entre usar EKS (Kubernetes) o mantener la arquitectura actual con EC2/ASG.

---

#### [Resumen de Revisión](RESUMEN_REVISION.md)
Documento que resume el estado del proyecto después de la revisión completa.

**Contenido:**
- Correcciones realizadas
- Estado de cada módulo
- Verificaciones completadas
- Checklist de completitud

**Cuándo usar**: Para entender el estado actual del proyecto y las verificaciones realizadas.

---

## 📋 Documentos Históricos (Referencia)

### [Estructura del Proyecto](ESTRUCTURA_PROYECTO.md)
Documento que explica la estructura de carpetas y organización del proyecto.

**Nota**: Este documento puede estar desactualizado. Ver el README principal para la estructura actual.

---

### [Migración Modular](MIGRACION_MODULAR.md)
Documento que describe el proceso de migración a estructura modular.

**Nota**: La migración ya está completada. Este documento es solo para referencia histórica.

---

## 🎯 Guía Rápida por Caso de Uso

### "Necesito configurar variables de entorno"
→ Lee **[Variables de Entorno](VARIABLES_DE_ENTORNO.md)**

### "Necesito configurar comunicación entre servicios"
→ Lee **[Comunicación entre Servicios](COMUNICACION_SERVICIOS.md)**

### "¿Debo usar EKS o EC2?"
→ Lee **[EKS vs EC2](EKS_VS_EC2.md)**

### "Quiero entender el estado del proyecto"
→ Lee **[Resumen de Revisión](RESUMEN_REVISION.md)**

### "Necesito ver la estructura del proyecto"
→ Lee el **README principal** en la raíz del proyecto

---

## 📁 Estructura de Documentación

```
docs/
├── README.md                    # Este archivo - Índice de documentación
├── VARIABLES_DE_ENTORNO.md     # ✅ Guía completa de variables de entorno
├── COMUNICACION_SERVICIOS.md   # ✅ Guía de comunicación entre servicios
├── EKS_VS_EC2.md              # ✅ Comparación EKS vs EC2
├── RESUMEN_REVISION.md         # ✅ Estado del proyecto
├── ESTRUCTURA_PROYECTO.md      # 📜 Referencia histórica
└── MIGRACION_MODULAR.md        # 📜 Referencia histórica
```

---

## 🔄 Actualización de Documentación

Esta documentación se actualiza cuando:
- Se agregan nuevas características
- Se corrigen problemas
- Se mejoran las configuraciones
- Se realizan cambios importantes en la estructura

**Última actualización**: Después de la migración completa a estructura modular.

---

## 📞 Recursos Adicionales

### Documentación Oficial
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CodeBuild](https://docs.aws.amazon.com/codebuild/)
- [AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/)
- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)

### Ejemplos de Código
Los ejemplos prácticos están en `../ejemplos/`:
- `buildspec.yml.example` - Configuración de CodeBuild
- `ejemplo-nodejs-api-gateway.js` - Uso de API Gateway
- `ejemplo-nodejs-sns-sqs.js` - Uso de SNS y SQS
- `ejemplo-nodejs-mysql.js` - Conexión a MySQL

---

**Nota**: Si encuentras información desactualizada o tienes sugerencias, actualiza la documentación correspondiente.

