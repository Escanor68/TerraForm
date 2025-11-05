/**
 * Ejemplos de uso de SNS y SQS con Node.js
 * Comunicación asíncrona entre backends
 */

const AWS = require('aws-sdk');

// Configurar AWS SDK
const sns = new AWS.SNS({ region: process.env.AWS_DEFAULT_REGION });
const sqs = new AWS.SQS({ region: process.env.AWS_DEFAULT_REGION });

// ============================================
// SNS - Publicar mensajes a Topics
// ============================================

/**
 * Publicar un evento usando SNS
 */
async function publishEvent(eventType, data) {
  try {
    const params = {
      TopicArn: process.env.SNS_EVENTS_TOPIC_ARN,
      Message: JSON.stringify({
        eventType,
        data,
        timestamp: new Date().toISOString(),
        source: process.env.PROJECT_NAME || 'unknown'
      }),
      MessageAttributes: {
        'eventType': {
          DataType: 'String',
          StringValue: eventType
        }
      }
    };

    const result = await sns.publish(params).promise();
    console.log('Evento publicado:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error publicando evento:', error);
    throw error;
  }
}

/**
 * Publicar una notificación usando SNS
 */
async function publishNotification(title, message, priority = 'normal') {
  try {
    const params = {
      TopicArn: process.env.SNS_NOTIFICATIONS_TOPIC_ARN,
      Message: JSON.stringify({
        title,
        message,
        priority,
        timestamp: new Date().toISOString()
      }),
      MessageAttributes: {
        'priority': {
          DataType: 'String',
          StringValue: priority
        }
      }
    };

    const result = await sns.publish(params).promise();
    console.log('Notificación publicada:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error publicando notificación:', error);
    throw error;
  }
}

/**
 * Publicar datos para procesamiento
 */
async function publishDataProcessing(taskId, data) {
  try {
    const params = {
      TopicArn: process.env.SNS_DATA_PROCESSING_TOPIC_ARN,
      Message: JSON.stringify({
        taskId,
        data,
        timestamp: new Date().toISOString()
      }),
      MessageAttributes: {
        'taskId': {
          DataType: 'String',
          StringValue: taskId
        }
      }
    };

    const result = await sns.publish(params).promise();
    console.log('Datos enviados para procesamiento:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error publicando datos:', error);
    throw error;
  }
}

// ============================================
// SQS - Enviar y recibir mensajes
// ============================================

/**
 * Enviar mensaje a una cola SQS
 */
async function sendMessageToQueue(queueUrl, messageBody, messageAttributes = {}) {
  try {
    const params = {
      QueueUrl: queueUrl,
      MessageBody: JSON.stringify(messageBody),
      MessageAttributes: Object.keys(messageAttributes).reduce((acc, key) => {
        acc[key] = {
          DataType: 'String',
          StringValue: String(messageAttributes[key])
        };
        return acc;
      }, {})
    };

    const result = await sqs.sendMessage(params).promise();
    console.log('Mensaje enviado a cola:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error enviando mensaje:', error);
    throw error;
  }
}

/**
 * Recibir mensajes de una cola SQS
 */
async function receiveMessagesFromQueue(queueUrl, maxMessages = 1, waitTimeSeconds = 20) {
  try {
    const params = {
      QueueUrl: queueUrl,
      MaxNumberOfMessages: maxMessages,
      WaitTimeSeconds: waitTimeSeconds,
      MessageAttributeNames: ['All']
    };

    const result = await sqs.receiveMessage(params).promise();
    
    if (result.Messages && result.Messages.length > 0) {
      console.log(`Mensajes recibidos: ${result.Messages.length}`);
      return result.Messages;
    }
    
    return [];
  } catch (error) {
    console.error('Error recibiendo mensajes:', error);
    throw error;
  }
}

/**
 * Eliminar mensaje de una cola SQS (después de procesarlo)
 */
async function deleteMessageFromQueue(queueUrl, receiptHandle) {
  try {
    const params = {
      QueueUrl: queueUrl,
      ReceiptHandle: receiptHandle
    };

    await sqs.deleteMessage(params).promise();
    console.log('Mensaje eliminado de la cola');
  } catch (error) {
    console.error('Error eliminando mensaje:', error);
    throw error;
  }
}

/**
 * Procesar mensajes de la cola de eventos
 */
async function processEventsQueue() {
  const queueUrl = process.env.SQS_EVENTS_QUEUE_URL;
  
  while (true) {
    try {
      const messages = await receiveMessagesFromQueue(queueUrl, 10, 20);
      
      for (const message of messages) {
        try {
          const body = JSON.parse(message.Body);
          console.log('Procesando evento:', body);
          
          // Procesar el evento aquí
          // ... tu lógica de procesamiento ...
          
          // Eliminar el mensaje después de procesarlo
          await deleteMessageFromQueue(queueUrl, message.ReceiptHandle);
        } catch (error) {
          console.error('Error procesando mensaje:', error);
          // El mensaje volverá a la cola después del visibility timeout
        }
      }
    } catch (error) {
      console.error('Error en el loop de procesamiento:', error);
      await new Promise(resolve => setTimeout(resolve, 5000)); // Esperar 5 segundos antes de reintentar
    }
  }
}

// ============================================
// Ejemplos de uso
// ============================================

async function ejemplo() {
  try {
    // Ejemplo 1: Publicar evento usando SNS
    await publishEvent('user.created', {
      userId: '123',
      email: 'user@example.com'
    });

    // Ejemplo 2: Publicar notificación
    await publishNotification(
      'Nuevo usuario registrado',
      'Un nuevo usuario se ha registrado en el sistema',
      'high'
    );

    // Ejemplo 3: Enviar datos para procesamiento
    await publishDataProcessing('task-123', {
      fileId: 'file-456',
      operation: 'process'
    });

    // Ejemplo 4: Enviar mensaje directamente a SQS
    await sendMessageToQueue(
      process.env.SQS_NOTIFICATIONS_QUEUE_URL,
      {
        type: 'email',
        to: 'user@example.com',
        subject: 'Bienvenido',
        body: 'Gracias por registrarte'
      },
      {
        priority: 'high',
        type: 'email'
      }
    );

    // Ejemplo 5: Procesar cola de eventos (ejecutar en un worker separado)
    // processEventsQueue();

  } catch (error) {
    console.error('Error en ejemplo:', error);
    process.exit(1);
  }
}

// Exportar funciones para uso en otros módulos
module.exports = {
  publishEvent,
  publishNotification,
  publishDataProcessing,
  sendMessageToQueue,
  receiveMessagesFromQueue,
  deleteMessageFromQueue,
  processEventsQueue
};

// Ejecutar ejemplo si se llama directamente
if (require.main === module) {
  ejemplo().then(() => {
    console.log('Ejemplo completado');
    process.exit(0);
  }).catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
}

