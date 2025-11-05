# Guía de Comunicación entre Servicios

Este documento explica cómo usar API Gateway, SNS y SQS para la comunicación entre frontend, backend y entre diferentes backends.

## Arquitectura de Comunicación

```
Frontend (React/Vue/etc)
    ↓ HTTP/HTTPS
API Gateway
    ↓ HTTP
Application Load Balancer
    ↓ HTTP
Backend Instances (EC2)
    ↓ SNS/SQS
Otros Backends o Workers
```

## 1. API Gateway - Comunicación Front-Back

### Descripción

API Gateway expone tus APIs REST para que el frontend se comunique con el backend de forma segura. Incluye:

- CORS configurado automáticamente
- Throttling por entorno
- Logging en CloudWatch
- Stages separados por entorno (dev, preprod, prod)

### URLs por Entorno

Las URLs se generan automáticamente y están disponibles como variables de entorno:

- **Dev**: `https://{api-id}.execute-api.{region}.amazonaws.com/dev`
- **Preprod**: `https://{api-id}.execute-api.{region}.amazonaws.com/preprod`
- **Prod**: `https://{api-id}.execute-api.{region}.amazonaws.com/prod`

### Variables de Entorno Disponibles

- `API_GATEWAY_URL` - URL completa del API Gateway para el entorno actual

### Ejemplo de Uso en Frontend

```javascript
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'https://your-api-id.execute-api.us-east-1.amazonaws.com/dev';

const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Ejemplo de uso
async function getUsers() {
  const response = await apiClient.get('/api/users');
  return response.data;
}
```

### Ejemplo de Uso en Backend (Node.js)

Ver archivo `ejemplo-nodejs-api-gateway.js` para ejemplos completos.

### Configuración CORS

Los orígenes permitidos se configuran en `terraform.tfvars`:

```hcl
cors_origins = [
  "http://localhost:3000",
  "https://dev.tudominio.com",
  "https://tudominio.com"
]
```

## 2. SNS - Comunicación Asíncrona entre Backends

### Descripción

Amazon SNS (Simple Notification Service) permite publicar mensajes a topics que pueden ser recibidos por múltiples suscriptores. Ideal para:

- Eventos del sistema
- Notificaciones
- Desacoplamiento de servicios

### Topics Disponibles

1. **Events Topic** (`SNS_EVENTS_TOPIC_ARN`)
   - Para eventos del sistema (user.created, order.placed, etc.)

2. **Notifications Topic** (`SNS_NOTIFICATIONS_TOPIC_ARN`)
   - Para notificaciones a usuarios (emails, SMS, push, etc.)

3. **Data Processing Topic** (`SNS_DATA_PROCESSING_TOPIC_ARN`)
   - Para tareas de procesamiento de datos

### Variables de Entorno Disponibles

- `SNS_EVENTS_TOPIC_ARN`
- `SNS_NOTIFICATIONS_TOPIC_ARN`
- `SNS_DATA_PROCESSING_TOPIC_ARN`

### Ejemplo de Uso

```javascript
const AWS = require('aws-sdk');
const sns = new AWS.SNS({ region: process.env.AWS_DEFAULT_REGION });

// Publicar un evento
async function publishEvent(eventType, data) {
  const params = {
    TopicArn: process.env.SNS_EVENTS_TOPIC_ARN,
    Message: JSON.stringify({
      eventType,
      data,
      timestamp: new Date().toISOString()
    })
  };
  
  await sns.publish(params).promise();
}

// Usar
await publishEvent('user.created', {
  userId: '123',
  email: 'user@example.com'
});
```

Ver archivo `ejemplo-nodejs-sns-sqs.js` para más ejemplos.

### Suscripciones Automáticas

Los topics están suscritos automáticamente a colas SQS para procesamiento:

- Events Topic → Events Queue
- Notifications Topic → Notifications Queue
- Data Processing Topic → Data Processing Queue

## 3. SQS - Colas de Mensajes

### Descripción

Amazon SQS (Simple Queue Service) proporciona colas de mensajes para:

- Procesamiento asíncrono
- Desacoplamiento de servicios
- Manejo de carga
- Dead Letter Queues (DLQ) para mensajes fallidos

### Queues Disponibles

1. **Events Queue** (`SQS_EVENTS_QUEUE_URL`)
   - Mensajes de eventos del sistema
   - Conectada al Events SNS Topic

2. **Notifications Queue** (`SQS_NOTIFICATIONS_QUEUE_URL`)
   - Mensajes de notificaciones
   - Conectada al Notifications SNS Topic

3. **Data Processing Queue** (`SQS_DATA_PROCESSING_QUEUE_URL`)
   - Tareas de procesamiento de datos
   - Conectada al Data Processing SNS Topic
   - Incluye DLQ para mensajes fallidos

### Variables de Entorno Disponibles

- `SQS_EVENTS_QUEUE_URL`
- `SQS_NOTIFICATIONS_QUEUE_URL`
- `SQS_DATA_PROCESSING_QUEUE_URL`

### Ejemplo de Uso - Enviar Mensaje

```javascript
const AWS = require('aws-sdk');
const sqs = new AWS.SQS({ region: process.env.AWS_DEFAULT_REGION });

async function sendMessage(queueUrl, messageBody) {
  const params = {
    QueueUrl: queueUrl,
    MessageBody: JSON.stringify(messageBody)
  };
  
  await sqs.sendMessage(params).promise();
}

// Usar
await sendMessage(process.env.SQS_EVENTS_QUEUE_URL, {
  type: 'user.created',
  userId: '123'
});
```

### Ejemplo de Uso - Procesar Mensajes

```javascript
async function processMessages(queueUrl) {
  const params = {
    QueueUrl: queueUrl,
    MaxNumberOfMessages: 10,
    WaitTimeSeconds: 20 // Long polling
  };
  
  const result = await sqs.receiveMessage(params).promise();
  
  if (result.Messages) {
    for (const message of result.Messages) {
      const body = JSON.parse(message.Body);
      
      // Procesar mensaje
      await processMessage(body);
      
      // Eliminar mensaje después de procesarlo
      await sqs.deleteMessage({
        QueueUrl: queueUrl,
        ReceiptHandle: message.ReceiptHandle
      }).promise();
    }
  }
}
```

Ver archivo `ejemplo-nodejs-sns-sqs.js` para ejemplos completos.

## Patrones de Comunicación

### Patrón 1: Frontend → Backend (Síncrono)

```
Frontend → API Gateway → Load Balancer → Backend
```

**Cuándo usar**: Requests HTTP normales (GET, POST, PUT, DELETE)

**Ejemplo**: Obtener lista de usuarios, crear un pedido, actualizar perfil

### Patrón 2: Backend → Backend (Asíncrono con SNS)

```
Backend A → SNS Topic → [Múltiples suscriptores]
                         ├─→ Backend B (SQS)
                         ├─→ Backend C (SQS)
                         └─→ Lambda Function
```

**Cuándo usar**: Eventos que múltiples servicios necesitan procesar

**Ejemplo**: Cuando se crea un usuario, notificar a múltiples servicios

### Patrón 3: Backend → Worker (Con SQS)

```
Backend → SQS Queue → Worker Process
```

**Cuándo usar**: Tareas pesadas que se procesan en background

**Ejemplo**: Procesar imágenes, enviar emails masivos, generar reportes

### Patrón 4: SNS → SQS (Pub/Sub con Colas)

```
Backend A → SNS Topic → SQS Queue → Worker Process
```

**Cuándo usar**: Desacoplamiento completo entre servicios

**Ejemplo**: Sistema de eventos que necesita procesamiento asíncrono

## Ejemplos Completos

### Ejemplo 1: Frontend llama API

```javascript
// Frontend (React)
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL;

export async function getUsers() {
  const response = await axios.get(`${API_URL}/api/users`);
  return response.data;
}
```

### Ejemplo 2: Backend publica evento

```javascript
// Backend (Node.js/Express)
const { publishEvent } = require('./ejemplo-nodejs-sns-sqs');

app.post('/api/users', async (req, res) => {
  // Crear usuario en base de datos
  const user = await createUser(req.body);
  
  // Publicar evento
  await publishEvent('user.created', {
    userId: user.id,
    email: user.email
  });
  
  res.json(user);
});
```

### Ejemplo 3: Worker procesa cola

```javascript
// Worker Process
const { processEventsQueue } = require('./ejemplo-nodejs-sns-sqs');

// Procesar cola continuamente
processEventsQueue(); // Este es un loop infinito
```

## Instalación de Dependencias

Para usar SNS y SQS en Node.js:

```bash
npm install aws-sdk
```

Para usar API Gateway desde frontend:

```bash
npm install axios  # o fetch nativo
```

## Configuración de Variables de Entorno

Las variables se configuran automáticamente en CodeBuild y están disponibles en:

- Variables de entorno de CodeBuild
- Variables de entorno de las instancias EC2
- Outputs de Terraform (para referencia)

## Seguridad

- **Encriptación**: SNS y SQS están encriptados con KMS (configurable)
- **IAM**: Permisos específicos por servicio
- **CORS**: Configurado en API Gateway
- **VPC**: Backends en subnets privadas

## Monitoreo

- **API Gateway**: Logs en CloudWatch
- **SNS**: Métricas en CloudWatch
- **SQS**: Métricas de mensajes en cola, procesados, fallidos

## Troubleshooting

### Error de CORS en Frontend

Verifica que el origen del frontend esté en `cors_origins` en `terraform.tfvars`.

### Mensajes no se procesan en SQS

1. Verifica que el worker tenga permisos IAM
2. Verifica que la URL de la cola sea correcta
3. Revisa los logs de CloudWatch

### SNS no publica mensajes

1. Verifica permisos IAM del rol
2. Verifica que el Topic ARN sea correcto
3. Revisa métricas en CloudWatch

## Referencias

- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)
- [AWS SNS](https://docs.aws.amazon.com/sns/)
- [AWS SQS](https://docs.aws.amazon.com/sqs/)
- Ejemplos de código: `ejemplo-nodejs-api-gateway.js` y `ejemplo-nodejs-sns-sqs.js`

