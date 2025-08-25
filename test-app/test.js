// Simple test suite
const assert = require('assert');

console.log('Running tests...');

// Test 1: Basic functionality
try {
    assert.strictEqual(2 + 2, 4);
    console.log('✓ Math test passed');
} catch (error) {
    console.error('✗ Math test failed:', error.message);
    process.exit(1);
}

// Test 2: String operations
try {
    assert.strictEqual('hello'.toUpperCase(), 'HELLO');
    console.log('✓ String test passed');
} catch (error) {
    console.error('✗ String test failed:', error.message);
    process.exit(1);
}

// Test 3: Array operations
try {
    const arr = [1, 2, 3];
    assert.strictEqual(arr.length, 3);
    console.log('✓ Array test passed');
} catch (error) {
    console.error('✗ Array test failed:', error.message);
    process.exit(1);
}

// Simulate occasional failures (10% chance)
const shouldFail = Math.random() < 0.1;
if (shouldFail) {
    console.error('✗ Random test failure (simulated)');
    process.exit(1);
}

console.log('All tests passed! ✅');
console.log(`Test run completed at: ${new Date().toISOString()}`);
