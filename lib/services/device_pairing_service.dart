import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skadoosh_app/services/crypto_utils.dart';

class DevicePairingService {
  static const String _userKey = 'device_pairing_user';
  static const String _shareIdKey = 'device_pairing_share_id';
  static const String _usernameKey = 'device_pairing_username';

  String? _baseUrl;

  // Initialize with server URL
  void initialize(String baseUrl) {
    _baseUrl = baseUrl;
    print('Device pairing service initialized with: $_baseUrl');
  }

  bool get isConfigured => _baseUrl != null;

  // Check if user is registered
  Future<bool> isUserRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_shareIdKey) != null;
  }

  // Get current user info
  Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final shareId = prefs.getString(_shareIdKey);
    final username = prefs.getString(_usernameKey);

    if (shareId != null && username != null) {
      return {'shareId': shareId, 'username': username};
    }
    return null;
  }

  // Generate device ID
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor}';
      }
    } catch (e) {
      // Fallback
    }
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Generate device name
  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name}\'s ${iosInfo.model}';
      }
    } catch (e) {
      // Fallback
    }
    return 'Unknown Device';
  }

  // Register user with auto key generation
  Future<RegistrationResult> registerUser(String username) async {
    if (_baseUrl == null) {
      throw Exception('Device pairing service not configured');
    }

    try {
      print('🔑 Generating RSA keys automatically...');

      // Generate RSA keys automatically
      final keyPair = CryptoUtils.generateRSAKeyPair();
      final publicKeyJson = CryptoUtils.publicKeyToJson(keyPair.publicKey);
      final privateKeyJson = CryptoUtils.privateKeyToJson(keyPair.privateKey);

      // Get device info
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      print('📱 Registering user: $username with device: $deviceName');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'deviceName': deviceName,
          'publicKey': publicKeyJson,
          'deviceId': deviceId,
        }),
      );

      print('Registration response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Store user info and keys locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_shareIdKey, data['shareId']);
        await prefs.setString(_usernameKey, username);
        await prefs.setString('user_public_key', publicKeyJson);
        await prefs.setString('user_private_key', privateKeyJson);

        print(
          '✅ User registered successfully with Share ID: ${data['shareId']}',
        );

        return RegistrationResult(
          success: true,
          shareId: data['shareId'],
          username: username,
          syncGroupId: data['syncGroupId'],
        );
      } else if (response.statusCode == 409) {
        return RegistrationResult(
          success: false,
          error: 'Device already registered. Clear app data to re-register.',
        );
      } else {
        final errorData = jsonDecode(response.body);
        return RegistrationResult(
          success: false,
          error: errorData['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      print('Registration failed: $e');
      return RegistrationResult(
        success: false,
        error: 'Registration failed: $e',
      );
    }
  }

  // Lookup user by Share ID
  Future<UserLookupResult> lookupUser(String shareId) async {
    if (_baseUrl == null) {
      throw Exception('Device pairing service not configured');
    }

    try {
      print('🔍 Looking up Share ID: $shareId');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/lookup/$shareId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserLookupResult(
          found: true,
          username: data['username'],
          shareId: data['shareId'],
          memberSince: DateTime.parse(data['memberSince']),
        );
      } else if (response.statusCode == 404) {
        return UserLookupResult(found: false, error: 'Share ID not found');
      } else {
        return UserLookupResult(found: false, error: 'Lookup failed');
      }
    } catch (e) {
      return UserLookupResult(found: false, error: 'Lookup failed: $e');
    }
  }

  // Send pairing request
  Future<PairingResult> sendPairingRequest(String targetShareId) async {
    if (_baseUrl == null) {
      throw Exception('Device pairing service not configured');
    }

    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User not registered');
      }

      final deviceId = await _getDeviceId();

      print('📤 Sending pairing request to: $targetShareId');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/devices/pair-request'),
        headers: {
          'Content-Type': 'application/json',
          'device-id': deviceId,
          'share-id': user['shareId']!,
        },
        body: jsonEncode({'targetShareId': targetShareId}),
      );

      print(
        'Pairing request response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PairingResult(
          success: true,
          message: data['message'],
          targetUser: data['targetUser'],
        );
      } else if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        return PairingResult(success: false, error: data['error']);
      } else {
        final data = jsonDecode(response.body);
        return PairingResult(
          success: false,
          error: data['error'] ?? 'Failed to send pairing request',
        );
      }
    } catch (e) {
      return PairingResult(
        success: false,
        error: 'Failed to send pairing request: $e',
      );
    }
  }

  // Get pending pairing requests
  Future<List<PairingRequest>> getPendingRequests() async {
    if (_baseUrl == null) {
      throw Exception('Device pairing service not configured');
    }

    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User not registered');
      }

      final deviceId = await _getDeviceId();

      final response = await http.get(
        Uri.parse('$_baseUrl/api/devices/requests'),
        headers: {'device-id': deviceId, 'share-id': user['shareId']!},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requests = data['requests'] as List;

        return requests
            .map(
              (req) => PairingRequest(
                id: req['id'],
                fromUsername: req['from_username'],
                fromShareId: req['from_share_id'],
                fromDeviceName: req['from_device_name'],
                status: req['status'],
                createdAt: DateTime.parse(req['created_at']),
              ),
            )
            .toList();
      } else {
        throw Exception('Failed to get pending requests');
      }
    } catch (e) {
      print('Failed to get pending requests: $e');
      return [];
    }
  }

  // Respond to pairing request
  Future<PairingResult> respondToRequest(
    String requestId,
    String action,
  ) async {
    if (_baseUrl == null) {
      throw Exception('Device pairing service not configured');
    }

    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User not registered');
      }

      final deviceId = await _getDeviceId();

      print('🔄 ${action}ing pairing request: $requestId');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/devices/requests/$requestId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'device-id': deviceId,
          'share-id': user['shareId']!,
        },
        body: jsonEncode({'action': action}),
      );

      print('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PairingResult(
          success: true,
          message: data['message'],
          sharedGroupId: data['sharedGroupId'],
        );
      } else {
        final data = jsonDecode(response.body);
        return PairingResult(
          success: false,
          error: data['error'] ?? 'Failed to respond to request',
        );
      }
    } catch (e) {
      return PairingResult(
        success: false,
        error: 'Failed to respond to request: $e',
      );
    }
  }

  // Get paired devices
  Future<List<PairedDevice>> getPairedDevices() async {
    if (_baseUrl == null) {
      throw Exception('Device pairing service not configured');
    }

    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('User not registered');
      }

      final deviceId = await _getDeviceId();

      final response = await http.get(
        Uri.parse('$_baseUrl/api/devices/paired'),
        headers: {'device-id': deviceId, 'share-id': user['shareId']!},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final devices = data['pairedDevices'] as List;

        return devices
            .map(
              (device) => PairedDevice(
                deviceName: device['device_name'],
                username: device['username'],
                shareId: device['share_id'],
                lastSeen: DateTime.parse(device['last_seen']),
                pairedAt: DateTime.parse(device['paired_at']),
                sharedGroupId: device['shared_group_id'],
              ),
            )
            .toList();
      } else {
        throw Exception('Failed to get paired devices');
      }
    } catch (e) {
      print('Failed to get paired devices: $e');
      return [];
    }
  }
}

// Data classes
class RegistrationResult {
  final bool success;
  final String? shareId;
  final String? username;
  final String? syncGroupId;
  final String? error;

  RegistrationResult({
    required this.success,
    this.shareId,
    this.username,
    this.syncGroupId,
    this.error,
  });
}

class UserLookupResult {
  final bool found;
  final String? username;
  final String? shareId;
  final DateTime? memberSince;
  final String? error;

  UserLookupResult({
    required this.found,
    this.username,
    this.shareId,
    this.memberSince,
    this.error,
  });
}

class PairingResult {
  final bool success;
  final String? message;
  final String? targetUser;
  final String? sharedGroupId;
  final String? error;

  PairingResult({
    required this.success,
    this.message,
    this.targetUser,
    this.sharedGroupId,
    this.error,
  });
}

class PairingRequest {
  final String id;
  final String fromUsername;
  final String fromShareId;
  final String fromDeviceName;
  final String status;
  final DateTime createdAt;

  PairingRequest({
    required this.id,
    required this.fromUsername,
    required this.fromShareId,
    required this.fromDeviceName,
    required this.status,
    required this.createdAt,
  });
}

class PairedDevice {
  final String deviceName;
  final String username;
  final String shareId;
  final DateTime lastSeen;
  final DateTime pairedAt;
  final String sharedGroupId;

  PairedDevice({
    required this.deviceName,
    required this.username,
    required this.shareId,
    required this.lastSeen,
    required this.pairedAt,
    required this.sharedGroupId,
  });
}
