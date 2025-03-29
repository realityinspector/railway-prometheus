import { Redis } from 'ioredis';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Validate required environment variables
const requiredEnvVars = ['DATABASE_ORCHESTRATOR_URL', 'MAIN_FASTAPI_URL'];
const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingEnvVars.length > 0) {
  throw new Error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
}

export class DatabaseOrchestrator {
  constructor(config = {}) {
    this.orchestratorUrl = config.orchestratorUrl || process.env.DATABASE_ORCHESTRATOR_URL;
    this.fastapiUrl = config.fastapiUrl || process.env.MAIN_FASTAPI_URL;
    
    if (!this.orchestratorUrl || !this.fastapiUrl) {
      throw new Error('Missing required URLs for DatabaseOrchestrator');
    }

    // Initialize Redis client with error handling
    try {
      this.redisClient = new Redis(this.orchestratorUrl, {
        retryStrategy: (times) => {
          const delay = Math.min(times * 50, 2000);
          return delay;
        },
        maxRetriesPerRequest: 3,
      });

      this.redisClient.on('error', (err) => {
        console.error('Redis connection error:', err);
      });
    } catch (error) {
      console.error('Failed to initialize Redis client:', error);
      throw error;
    }
  }

  async executePostgresQuery(queryFn, options = {}) {
    try {
      const response = await fetch(`${this.orchestratorUrl}/execute/pg_query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          data: {
            query: queryFn.toString(),
          },
          options: {
            operationName: options.operationName || 'default_operation',
            timeoutMs: options.timeoutMs || 10000,
            maxRetries: options.maxRetries || 3,
          },
        }),
      });

      if (!response.ok) {
        throw new Error(`Postgres query failed: ${response.statusText}`);
      }

      return response.json();
    } catch (error) {
      console.error('Postgres query error:', error);
      throw error;
    }
  }

  async executeRedisCommand(commandFn, options = {}) {
    try {
      const response = await fetch(`${this.orchestratorUrl}/execute/redis_exec`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          data: {
            command: commandFn.toString(),
          },
          options: {
            operationName: options.operationName || 'default_operation',
            timeoutMs: options.timeoutMs || 5000,
            maxRetries: options.maxRetries || 3,
          },
        }),
      });

      if (!response.ok) {
        throw new Error(`Redis command failed: ${response.statusText}`);
      }

      return response.json();
    } catch (error) {
      console.error('Redis command error:', error);
      throw error;
    }
  }

  async getFastAPIMetrics() {
    try {
      const response = await fetch(`${this.fastapiUrl}/metrics`);
      if (!response.ok) {
        throw new Error(`Failed to fetch FastAPI metrics: ${response.statusText}`);
      }
      return response.json();
    } catch (error) {
      console.error('FastAPI metrics error:', error);
      throw error;
    }
  }
} 