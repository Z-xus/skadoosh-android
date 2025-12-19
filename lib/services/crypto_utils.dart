import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class CryptoUtils {
  static const int _keySize = 2048; // RSA key size

  // Generate RSA key pair
  static RSAKeyPair generateRSAKeyPair() {
    final keyGen = RSAKeyGenerator();
    final secureRandom = FortunaRandom();

    // Seed the random number generator
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Generate key pair
    keyGen.init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), _keySize, 64),
        secureRandom,
      ),
    );

    final pair = keyGen.generateKeyPair();
    return RSAKeyPair(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  // Convert RSA public key to JSON format for server compatibility
  static String publicKeyToJson(RSAPublicKey publicKey) {
    final modulus = base64.encode(_bigIntToBytes(publicKey.modulus!));
    final exponent = base64.encode(_bigIntToBytes(publicKey.exponent!));

    return jsonEncode({'n': modulus, 'e': exponent});
  }

  // Convert RSA private key to a simple JSON format for storage
  static String privateKeyToJson(RSAPrivateKey privateKey) {
    return jsonEncode({
      'modulus': base64.encode(_bigIntToBytes(privateKey.modulus!)),
      'exponent': base64.encode(_bigIntToBytes(privateKey.exponent!)),
      'privateExponent': base64.encode(
        _bigIntToBytes(privateKey.privateExponent!),
      ),
      'p': base64.encode(_bigIntToBytes(privateKey.p!)),
      'q': base64.encode(_bigIntToBytes(privateKey.q!)),
    });
  }

  // Parse JSON private key back to RSAPrivateKey object
  static RSAPrivateKey parsePrivateKeyFromJson(String jsonStr) {
    try {
      final keyData = jsonDecode(jsonStr) as Map<String, dynamic>;

      final modulus = _bytesToBigInt(
        base64.decode(keyData['modulus'] as String),
      );
      final exponent = _bytesToBigInt(
        base64.decode(keyData['exponent'] as String),
      );
      final privateExponent = _bytesToBigInt(
        base64.decode(keyData['privateExponent'] as String),
      );
      final p = _bytesToBigInt(base64.decode(keyData['p'] as String));
      final q = _bytesToBigInt(base64.decode(keyData['q'] as String));

      return RSAPrivateKey(modulus, privateExponent, p, q);
    } catch (e) {
      print('Error parsing private key from JSON: $e');
      throw FormatException('Invalid private key format');
    }
  }

  // Generate fingerprint from public key
  static String getFingerprint(String publicKeyPem) {
    final hash = sha256.convert(utf8.encode(publicKeyPem));
    return hash.toString().substring(0, 16); // First 16 chars for readability
  }

  // Sign data with private key (compatible with node-rsa)
  static String signData(String data, RSAPrivateKey privateKey) {
    // Use PKCS1v15 signing scheme to match node-rsa default
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signature = signer.generateSignature(
      Uint8List.fromList(utf8.encode(data)),
    );
    return base64.encode(signature.bytes);
  }

  // Parse private key with backward compatibility
  static RSAPrivateKey parsePrivateKeyFromPem(String keyData) {
    try {
      print('Parsing private key (length: ${keyData.length})');

      if (keyData.trim().startsWith('{') && keyData.trim().endsWith('}')) {
        // New JSON format
        return parsePrivateKeyFromJson(keyData);
      } else if (keyData.contains('-----BEGIN PRIVATE KEY-----')) {
        // Old PEM format - suggest regeneration
        throw FormatException(
          'Legacy key format detected. Please regenerate your key pair to use the current format.',
        );
      } else {
        // Try to parse as JSON (in case it's missing braces)
        return parsePrivateKeyFromJson(keyData);
      }
    } catch (e) {
      print('Error parsing private key: $e');
      if (e is FormatException) {
        rethrow;
      }
      throw FormatException(
        'Invalid private key format. Please regenerate your key pair.',
      );
    }
  }

  // Generate challenge string
  static String generateChallenge() {
    final random = Random.secure();
    final bytes = List.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  // Helper: Convert BigInt to bytes
  static List<int> _bigIntToBytes(BigInt bigInt) {
    final hex = bigInt.toRadixString(16);
    final paddedHex = hex.length % 2 == 0 ? hex : '0$hex';
    final bytes = <int>[];

    for (int i = 0; i < paddedHex.length; i += 2) {
      bytes.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
    }

    return bytes;
  }

  // Helper: Convert bytes to BigInt
  static BigInt _bytesToBigInt(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) + BigInt.from(bytes[i]);
    }
    return result;
  }

  // Format base64 string for PEM
  static String _formatBase64(String base64String) {
    final regex = RegExp('.{1,64}');
    return regex.allMatches(base64String).map((m) => m.group(0)).join('\n');
  }
}

class RSAKeyPair {
  final RSAPublicKey publicKey;
  final RSAPrivateKey privateKey;

  RSAKeyPair(this.publicKey, this.privateKey);
}

class KeyPairInfo {
  final String publicKeyPem;
  final String privateKeyPem;
  final String fingerprint;
  final RSAPrivateKey privateKey;

  KeyPairInfo({
    required this.publicKeyPem,
    required this.privateKeyPem,
    required this.fingerprint,
    required this.privateKey,
  });

  Map<String, String> toMap() {
    return {
      'publicKey': publicKeyPem,
      'privateKey': privateKeyPem,
      'fingerprint': fingerprint,
    };
  }

  factory KeyPairInfo.fromKeyPair(RSAKeyPair keyPair) {
    final publicKeyJson = CryptoUtils.publicKeyToJson(keyPair.publicKey);
    final privateKeyJson = CryptoUtils.privateKeyToJson(keyPair.privateKey);
    final fingerprint = CryptoUtils.getFingerprint(publicKeyJson);

    return KeyPairInfo(
      publicKeyPem: publicKeyJson,
      privateKeyPem: privateKeyJson,
      fingerprint: fingerprint,
      privateKey: keyPair.privateKey,
    );
  }

  factory KeyPairInfo.fromMap(Map<String, dynamic> map) {
    final publicKeyPem = map['publicKey'] as String?;
    final privateKeyPem = map['privateKey'] as String?;
    final fingerprint = map['fingerprint'] as String?;

    if (publicKeyPem == null || privateKeyPem == null || fingerprint == null) {
      throw FormatException('Invalid key data: missing required fields');
    }

    // Parse the private key from stored format
    final privateKey = CryptoUtils.parsePrivateKeyFromPem(privateKeyPem);

    return KeyPairInfo(
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      fingerprint: fingerprint,
      privateKey: privateKey,
    );
  }
}
