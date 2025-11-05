/**
 * Ejemplo de conexión a MySQL con Node.js usando las variables de entorno
 * Este archivo muestra cómo usar las variables configuradas en Terraform
 */

const mysql = require('mysql2/promise');

// Configuración de conexión usando variables de entorno
const dbConfig = {
  host: process.env.MYSQL_HOST,
  port: parseInt(process.env.MYSQL_PORT || '3306'),
  database: process.env.MYSQL_DATABASE,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD, // Viene de Parameter Store
  waitForConnections: true,
  connectionLimit: parseInt(process.env.MYSQL_POOL_SIZE || '10'),
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  // Timeout de conexión
  connectTimeout: parseInt(process.env.MYSQL_CONNECTION_TIMEOUT || '10000'),
};

// Crear pool de conexiones
const pool = mysql.createPool(dbConfig);

// Función para ejecutar queries
async function query(sql, params) {
  try {
    const [rows] = await pool.execute(sql, params);
    return rows;
  } catch (error) {
    console.error('Error ejecutando query:', error);
    throw error;
  }
}

// Función para obtener una conexión del pool
async function getConnection() {
  try {
    const connection = await pool.getConnection();
    return connection;
  } catch (error) {
    console.error('Error obteniendo conexión:', error);
    throw error;
  }
}

// Ejemplo de uso
async function ejemplo() {
  try {
    // Ejemplo 1: Query simple
    const usuarios = await query('SELECT * FROM usuarios LIMIT ?', [10]);
    console.log('Usuarios encontrados:', usuarios.length);

    // Ejemplo 2: Usar transacciones
    const connection = await getConnection();
    try {
      await connection.beginTransaction();

      await connection.execute(
        'INSERT INTO usuarios (nombre, email) VALUES (?, ?)',
        ['Juan', 'juan@example.com']
      );

      await connection.commit();
      console.log('Transacción completada');
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }

    // Ejemplo 3: Verificar estado de la conexión
    const [result] = await pool.execute('SELECT 1 as test');
    console.log('Conexión a MySQL exitosa:', result[0].test === 1);

  } catch (error) {
    console.error('Error en ejemplo:', error);
    process.exit(1);
  }
}

// Cerrar pool al terminar (opcional, el pool se cierra automáticamente)
process.on('SIGINT', async () => {
  console.log('Cerrando pool de conexiones...');
  await pool.end();
  process.exit(0);
});

// Exportar para uso en otros módulos
module.exports = {
  pool,
  query,
  getConnection,
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

