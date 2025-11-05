/**
 * Ejemplo de cliente para comunicarse con API Gateway desde el frontend
 * O para usar en el backend para hacer requests a otras APIs
 */

const axios = require('axios');

// URL del API Gateway (viene de variable de entorno)
const API_GATEWAY_URL = process.env.API_GATEWAY_URL || 'https://your-api-id.execute-api.us-east-1.amazonaws.com/dev';

// Cliente HTTP configurado para API Gateway
const apiClient = axios.create({
  baseURL: API_GATEWAY_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    // Agregar headers de autenticación si es necesario
    // 'Authorization': `Bearer ${token}`
  }
});

// Interceptor para agregar token de autenticación (si es necesario)
apiClient.interceptors.request.use(
  (config) => {
    // Agregar token si existe
    const token = localStorage?.getItem('authToken') || process.env.AUTH_TOKEN;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Interceptor para manejar errores
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      // El servidor respondió con un código de error
      console.error('Error de API:', error.response.status, error.response.data);
    } else if (error.request) {
      // La solicitud fue hecha pero no hubo respuesta
      console.error('Sin respuesta del servidor:', error.request);
    } else {
      // Error al configurar la solicitud
      console.error('Error:', error.message);
    }
    return Promise.reject(error);
  }
);

// ============================================
// Funciones de ejemplo para diferentes endpoints
// ============================================

/**
 * Obtener usuarios
 */
async function getUsers() {
  try {
    const response = await apiClient.get('/api/users');
    return response.data;
  } catch (error) {
    console.error('Error obteniendo usuarios:', error);
    throw error;
  }
}

/**
 * Obtener un usuario por ID
 */
async function getUserById(userId) {
  try {
    const response = await apiClient.get(`/api/users/${userId}`);
    return response.data;
  } catch (error) {
    console.error('Error obteniendo usuario:', error);
    throw error;
  }
}

/**
 * Crear un nuevo usuario
 */
async function createUser(userData) {
  try {
    const response = await apiClient.post('/api/users', userData);
    return response.data;
  } catch (error) {
    console.error('Error creando usuario:', error);
    throw error;
  }
}

/**
 * Actualizar un usuario
 */
async function updateUser(userId, userData) {
  try {
    const response = await apiClient.put(`/api/users/${userId}`, userData);
    return response.data;
  } catch (error) {
    console.error('Error actualizando usuario:', error);
    throw error;
  }
}

/**
 * Eliminar un usuario
 */
async function deleteUser(userId) {
  try {
    const response = await apiClient.delete(`/api/users/${userId}`);
    return response.data;
  } catch (error) {
    console.error('Error eliminando usuario:', error);
    throw error;
  }
}

/**
 * Ejemplo de uso en el backend (Node.js/Express)
 */
function setupApiRoutes(app) {
  // Endpoint que usa el API Gateway interno
  app.get('/api/proxy/users', async (req, res) => {
    try {
      const users = await getUsers();
      res.json(users);
    } catch (error) {
      res.status(500).json({ error: 'Error obteniendo usuarios' });
    }
  });

  // Endpoint que combina datos locales con datos del API Gateway
  app.get('/api/combined-data', async (req, res) => {
    try {
      const [users, localData] = await Promise.all([
        getUsers(),
        // Obtener datos locales de tu base de datos
        // getLocalData()
      ]);
      
      res.json({
        users,
        localData
      });
    } catch (error) {
      res.status(500).json({ error: 'Error obteniendo datos combinados' });
    }
  });
}

// ============================================
// Ejemplo de uso en el frontend (React/Vue/etc)
// ============================================

/**
 * Hook de React para usar el API Gateway
 */
/*
import { useState, useEffect } from 'react';

function useApiGateway(endpoint) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);
        const response = await apiClient.get(endpoint);
        setData(response.data);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, [endpoint]);

  return { data, loading, error };
}

// Uso en un componente React
function UsersList() {
  const { data: users, loading, error } = useApiGateway('/api/users');

  if (loading) return <div>Cargando...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
*/

// ============================================
// Ejemplo de uso
// ============================================

async function ejemplo() {
  try {
    // Ejemplo 1: Obtener usuarios
    const users = await getUsers();
    console.log('Usuarios:', users);

    // Ejemplo 2: Crear un usuario
    const newUser = await createUser({
      name: 'Juan Pérez',
      email: 'juan@example.com'
    });
    console.log('Usuario creado:', newUser);

    // Ejemplo 3: Actualizar usuario
    const updatedUser = await updateUser(newUser.id, {
      name: 'Juan Carlos Pérez'
    });
    console.log('Usuario actualizado:', updatedUser);

  } catch (error) {
    console.error('Error en ejemplo:', error);
    process.exit(1);
  }
}

// Exportar funciones para uso en otros módulos
module.exports = {
  apiClient,
  getUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  setupApiRoutes
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

