const CryptoUtils = require('./src/utils/crypto');

// Test the server's own crypto utils
console.log('=== Testing Server Crypto Utils ===');

// Generate a key pair using server's method
console.log('1. Generating key pair using server method...');
const serverKeyPair = CryptoUtils.generateKeyPair();
console.log('   ✓ Generated key pair');
console.log('   ✓ Fingerprint:', serverKeyPair.fingerprint);
console.log('   ✓ Public key format:', typeof serverKeyPair.publicKey);
console.log('   ✓ Public key preview:', serverKeyPair.publicKey.substring(0, 100) + '...');

// Test signing and verification
const testData = 'test challenge data';
console.log('\n2. Testing sign and verify...');
const signature = CryptoUtils.signData(testData, serverKeyPair.privateKey);
console.log('   ✓ Generated signature:', signature.substring(0, 20) + '...');

const isValid = CryptoUtils.verifySignature(testData, signature, serverKeyPair.publicKey);
console.log('   ✓ Signature verification:', isValid ? 'SUCCESS' : 'FAILED');

console.log('\n=== Server Crypto Test Complete ===');