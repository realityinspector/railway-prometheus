import { DatabaseOrchestrator } from './database_orchestrator.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

class TestDataManager {
  constructor() {
    // DatabaseOrchestrator will now handle environment variables internally
    this.orchestrator = new DatabaseOrchestrator();
  }

  async seedTestData() {
    try {
      // Create test users
      const users = await this.orchestrator.executePostgresQuery(
        async (client) => {
          const result = await client.query(`
            INSERT INTO users (email, name, created_at)
            VALUES 
              ('test1@example.com', 'Test User 1', NOW()),
              ('test2@example.com', 'Test User 2', NOW()),
              ('test3@example.com', 'Test User 3', NOW())
            RETURNING id, email, name;
          `);
          return result.rows;
        },
        { operationName: 'seed_test_users' }
      );

      // Create test metrics
      const metrics = await this.orchestrator.executePostgresQuery(
        async (client) => {
          const result = await client.query(`
            INSERT INTO metrics (user_id, metric_name, value, timestamp)
            SELECT 
              u.id,
              m.metric_name,
              m.value,
              NOW() - (m.offset_minutes || ' minutes')::interval
            FROM users u
            CROSS JOIN (
              VALUES 
                ('cpu_usage', random() * 100, 0),
                ('memory_usage', random() * 100, 5),
                ('disk_usage', random() * 100, 10),
                ('network_io', random() * 1000, 15),
                ('error_rate', random() * 10, 20)
            ) AS m(metric_name, value, offset_minutes)
            WHERE u.email LIKE 'test%@example.com';
          `);
          return result.rows;
        },
        { operationName: 'seed_test_metrics' }
      );

      // Set up Redis test data
      await this.orchestrator.executeRedisCommand(
        async () => {
          const redis = this.orchestrator.redisClient;
          await redis.set('test:last_update', new Date().toISOString());
          await redis.set('test:data_version', '1.0');
          return true;
        },
        { operationName: 'seed_redis_test_data' }
      );

      return {
        users,
        metrics,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Error seeding test data:', error);
      throw error;
    }
  }

  async updateTestData() {
    try {
      // Update existing metrics with new random values
      const updatedMetrics = await this.orchestrator.executePostgresQuery(
        async (client) => {
          const result = await client.query(`
            UPDATE metrics
            SET 
              value = random() * 100,
              timestamp = NOW()
            WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%@example.com')
            RETURNING id, user_id, metric_name, value, timestamp;
          `);
          return result.rows;
        },
        { operationName: 'update_test_metrics' }
      );

      // Update Redis test data
      await this.orchestrator.executeRedisCommand(
        async () => {
          const redis = this.orchestrator.redisClient;
          await redis.set('test:last_update', new Date().toISOString());
          await redis.incr('test:data_version');
          return true;
        },
        { operationName: 'update_redis_test_data' }
      );

      return {
        updatedMetrics,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Error updating test data:', error);
      throw error;
    }
  }

  async rollbackTestData() {
    try {
      // Remove test users and their metrics
      const removedData = await this.orchestrator.executePostgresQuery(
        async (client) => {
          const result = await client.query(`
            WITH deleted_metrics AS (
              DELETE FROM metrics
              WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'test%@example.com')
              RETURNING *
            ),
            deleted_users AS (
              DELETE FROM users
              WHERE email LIKE 'test%@example.com'
              RETURNING *
            )
            SELECT 
              (SELECT COUNT(*) FROM deleted_metrics) as metrics_removed,
              (SELECT COUNT(*) FROM deleted_users) as users_removed;
          `);
          return result.rows[0];
        },
        { operationName: 'rollback_test_data' }
      );

      // Clear Redis test data
      await this.orchestrator.executeRedisCommand(
        async () => {
          const redis = this.orchestrator.redisClient;
          await redis.del('test:last_update', 'test:data_version');
          return true;
        },
        { operationName: 'clear_redis_test_data' }
      );

      return {
        removedData,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Error rolling back test data:', error);
      throw error;
    }
  }

  async getTestDataStatus() {
    try {
      const status = await this.orchestrator.executePostgresQuery(
        async (client) => {
          const result = await client.query(`
            SELECT 
              COUNT(DISTINCT u.id) as test_users,
              COUNT(m.id) as test_metrics
            FROM users u
            LEFT JOIN metrics m ON u.id = m.user_id
            WHERE u.email LIKE 'test%@example.com';
          `);
          return result.rows[0];
        },
        { operationName: 'get_test_data_status' }
      );

      const redisStatus = await this.orchestrator.executeRedisCommand(
        async () => {
          const redis = this.orchestrator.redisClient;
          const lastUpdate = await redis.get('test:last_update');
          const version = await redis.get('test:data_version');
          return { lastUpdate, version };
        },
        { operationName: 'get_redis_test_status' }
      );

      return {
        ...status,
        redis: redisStatus,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Error getting test data status:', error);
      throw error;
    }
  }
}

export default TestDataManager; 