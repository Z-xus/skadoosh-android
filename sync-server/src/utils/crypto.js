const crypto = require('crypto');
const NodeRSA = require('node-rsa');

class CryptoUtils {
  // Generate RSA key pair (similar to SSH key generation)
  static generateKeyPair() {
    const key = new NodeRSA({ b: 2048 });
    const privateKey = key.exportKey('private');
    const publicKey = key.exportKey('public');
    const fingerprint = this.getFingerprint(publicKey);
    
    return {
      privateKey,
      publicKey,
      fingerprint
    };
  }

  // Generate fingerprint from public key (like SSH key fingerprint)
  static getFingerprint(publicKey) {
    const hash = crypto.createHash('sha256');
    hash.update(publicKey);
    return hash.digest('hex').substring(0, 16); // First 16 chars for readability
  }

  // Sign data with private key
  static signData(data, privateKey) {
    const key = new NodeRSA(privateKey);
    const signature = key.sign(data, 'base64');
    return signature;
  }

  // Verify signature with public key
  static verifySignature(data, signature, publicKey) {
    try {
      // Check if publicKey is a JSON format (Flutter compatibility)
      let key;
      if (publicKey.startsWith('{')) {
        // JSON format: {"n": "modulus", "e": "exponent"}
        const keyData = JSON.parse(publicKey);
        key = new NodeRSA();
        key.importKey({
          n: Buffer.from(keyData.n, 'base64'),
          e: Buffer.from(keyData.e, 'base64'),
        }, 'components-public');
      } else {
        // PEM format
        key = new NodeRSA(publicKey);
      }
      
      return key.verify(data, signature, 'utf8', 'base64');
    } catch (error) {
      console.error('Signature verification failed:', error);
      return false;
    }
  }

  // Create challenge for authentication
  static createChallenge() {
    return crypto.randomBytes(32).toString('hex');
  }

  // Generate sync group identifier
  static generateGroupId(groupName) {
    const hash = crypto.createHash('sha256');
    hash.update(groupName);
    return hash.digest('hex').substring(0, 12); // Short, readable group ID
  }

  // Validate group name format
  static isValidGroupName(groupName) {
    // Allow alphanumeric, hyphens, underscores, 3-50 characters
    return /^[a-zA-Z0-9_-]{3,50}$/.test(groupName);
  }

  // Create device identifier (deterministic based on device info)
  static createDeviceId(deviceInfo) {
    const hash = crypto.createHash('sha256');
    hash.update(JSON.stringify(deviceInfo));
    return 'dev_' + hash.digest('hex').substring(0, 16);
  }
}

module.exports = CryptoUtils;