import TestDataManager from './test_data_manager.js';

const testDataManager = new TestDataManager();

async function main() {
  const command = process.argv[2];
  const args = process.argv.slice(3);

  try {
    switch (command) {
      case 'seed':
        console.log('Seeding test data...');
        const seedResult = await testDataManager.seedTestData();
        console.log('Test data seeded successfully:', seedResult);
        break;

      case 'update':
        console.log('Updating test data...');
        const updateResult = await testDataManager.updateTestData();
        console.log('Test data updated successfully:', updateResult);
        break;

      case 'rollback':
        console.log('Rolling back test data...');
        const rollbackResult = await testDataManager.rollbackTestData();
        console.log('Test data rolled back successfully:', rollbackResult);
        break;

      case 'status':
        console.log('Getting test data status...');
        const status = await testDataManager.getTestDataStatus();
        console.log('Test data status:', status);
        break;

      default:
        console.log(`
Usage: node manage_test_data.js <command>
Commands:
  seed      - Seed initial test data
  update    - Update existing test data with new random values
  rollback  - Remove all test data
  status    - Get current status of test data
        `);
        process.exit(1);
    }
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main(); 