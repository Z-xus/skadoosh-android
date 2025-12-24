import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:skadoosh_app/services/crypto_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ImageService {
  static const String _baseUrlKey = 'sync_server_url';
  static const String _fingerprintKey =
      'key_fingerprint'; // Match KeyBasedSyncService

  String? _baseUrl;
  String? _deviceId;
  String? _fingerprint;
  KeyPairInfo? _keyPair;

  // Initialize the service (compatible with KeyBasedSyncService)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    _fingerprint = prefs.getString(_fingerprintKey);

    // Load key pair info for signature generation
    final publicKeyJson = prefs.getString('user_public_key');
    final privateKeyJson = prefs.getString('user_private_key');

    if (publicKeyJson != null && privateKeyJson != null) {
      try {
        // Parse private key from JSON
        final privateKey = CryptoUtils.parsePrivateKeyFromJson(privateKeyJson);
        _keyPair = KeyPairInfo(
          publicKeyPem: publicKeyJson,
          privateKeyPem: privateKeyJson,
          fingerprint: _fingerprint ?? '',
          privateKey: privateKey,
        );
        print('ImageService: Keys loaded successfully');
      } catch (e) {
        print('ImageService: Error loading keys: $e');
      }
    }

    _deviceId = await _generateDeviceId();

    print('ImageService initialized:');
    print('- Base URL: $_baseUrl');
    print('- Fingerprint: $_fingerprint');
    print('- Device ID: $_deviceId');
    print('- Has Key Pair: ${_keyPair != null}');
  }

  // Generate unique device ID (same as KeyBasedSyncService)
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = 'ios_${iosInfo.identifierForVendor}';
      } else {
        deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    return deviceId;
  }

  // Check if the service is properly configured
  bool get isConfigured =>
      _baseUrl != null &&
      _deviceId != null &&
      _fingerprint != null &&
      _keyPair != null;

  // Generate authentication headers (same as KeyBasedSyncService)
  Future<Map<String, String>> _getAuthHeaders() async {
    if (!isConfigured || _keyPair == null || _fingerprint == null) {
      throw Exception('ImageService not configured');
    }

    // Get challenge from server (same as KeyBasedSyncService)
    final challengeResponse = await http.post(
      Uri.parse('$_baseUrl/api/auth/challenge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fingerprint': _fingerprint, 'deviceId': _deviceId}),
    );

    if (challengeResponse.statusCode != 200) {
      throw Exception(
        'Failed to get challenge: ${challengeResponse.statusCode} - ${challengeResponse.body}',
      );
    }

    final challengeData = jsonDecode(challengeResponse.body);
    final challenge = challengeData['challenge'] as String;

    // Sign the challenge with our private key
    final signature = CryptoUtils.signData(challenge, _keyPair!.privateKey);

    return {
      'Content-Type': 'application/json',
      'key-fingerprint': _fingerprint!,
      'device-id': _deviceId!,
      'challenge': challenge,
      'signature': signature,
    };
  }

  // Compress image if it's too large
  Future<Uint8List> _compressImage(
    Uint8List imageData, {
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    try {
      final originalImage = img.decodeImage(imageData);
      if (originalImage == null) return imageData;

      // If image is smaller than max width, return original
      if (originalImage.width <= maxWidth) return imageData;

      // Resize image
      final resized = img.copyResize(originalImage, width: maxWidth);

      // Encode as JPEG with compression
      final compressed = img.encodeJpg(resized, quality: quality);

      print(
        '🗜️ Compressed image: ${imageData.length} -> ${compressed.length} bytes',
      );
      return Uint8List.fromList(compressed);
    } catch (e) {
      print('❌ Error compressing image: $e');
      return imageData;
    }
  }

  // Upload image to server
  Future<ImageUploadResult> uploadImage({
    required File imageFile,
    required String noteId,
    bool compressImage = true,
  }) async {
    try {
      if (!isConfigured) {
        throw Exception(
          'ImageService not configured. Call initialize() first.',
        );
      }

      print('📤 Uploading image: ${imageFile.path}');

      // Read image data
      Uint8List imageData = await imageFile.readAsBytes();

      // Compress if needed
      if (compressImage) {
        imageData = await _compressImage(imageData);
      }

      // Prepare multipart request
      final uri = Uri.parse('$_baseUrl/api/images/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add headers (except Content-Type, which will be set by multipart)
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Add form fields
      request.fields['noteId'] = noteId;

      // Add image file
      final filename = path.basename(imageFile.path);
      final extension = path.extension(filename).toLowerCase();

      // Determine content type based on file extension
      String contentType = 'application/octet-stream'; // fallback
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
      }

      print(
        '📎 Uploading file: $filename (${imageData.length} bytes, $contentType)',
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageData,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageData = data['image'];

        print('✅ Image uploaded successfully: ${imageData['publicUrl']}');

        return ImageUploadResult(
          success: true,
          imageId: imageData['id'],
          filename: imageData['filename'],
          originalFilename: imageData['originalFilename'],
          publicUrl: imageData['publicUrl'],
          storagePath: imageData['storagePath'],
          contentType: imageData['contentType'],
          fileSize: imageData['fileSize'],
        );
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Image upload error: $e');
      return ImageUploadResult(success: false, error: e.toString());
    }
  }

  // Get images for a note
  Future<List<NoteImage>> getImagesForNote(String noteId) async {
    try {
      if (!isConfigured) {
        throw Exception('ImageService not configured');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/images/note/$noteId'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> imagesData = data['images'];

        return imagesData
            .map((imageData) => NoteImage.fromJson(imageData))
            .toList();
      } else {
        throw Exception('Failed to get images: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting images: $e');
      return [];
    }
  }

  // Delete an image
  Future<bool> deleteImage(String imageId) async {
    try {
      if (!isConfigured) {
        throw Exception('ImageService not configured');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/images/$imageId'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        print('✅ Image deleted successfully');
        return true;
      } else {
        throw Exception('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }

  // Get upload URL for direct client uploads (optional alternative approach)
  Future<UploadUrlResult?> getUploadUrl({
    required String filename,
    required String contentType,
    String? noteId,
  }) async {
    try {
      if (!isConfigured) {
        throw Exception('ImageService not configured');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/images/upload-url'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'filename': filename,
          'contentType': contentType,
          'noteId': noteId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UploadUrlResult.fromJson(data);
      } else {
        throw Exception('Failed to get upload URL: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting upload URL: $e');
      return null;
    }
  }
}

// Data classes for image handling

class ImageUploadResult {
  final bool success;
  final String? error;
  final String? imageId;
  final String? filename;
  final String? originalFilename;
  final String? publicUrl;
  final String? storagePath;
  final String? contentType;
  final int? fileSize;

  ImageUploadResult({
    required this.success,
    this.error,
    this.imageId,
    this.filename,
    this.originalFilename,
    this.publicUrl,
    this.storagePath,
    this.contentType,
    this.fileSize,
  });
}

class NoteImage {
  final String id;
  final String filename;
  final String originalFilename;
  final String publicUrl;
  final String storagePath;
  final String contentType;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteImage({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.publicUrl,
    required this.storagePath,
    required this.contentType,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteImage.fromJson(Map<String, dynamic> json) {
    return NoteImage(
      id: json['id'],
      filename: json['filename'],
      originalFilename: json['original_filename'],
      publicUrl: json['public_url'],
      storagePath: json['storage_path'],
      contentType: json['content_type'],
      fileSize: json['file_size'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class UploadUrlResult {
  final String uploadUrl;
  final String publicUrl;
  final String filePath;
  final int expiresIn;

  UploadUrlResult({
    required this.uploadUrl,
    required this.publicUrl,
    required this.filePath,
    required this.expiresIn,
  });

  factory UploadUrlResult.fromJson(Map<String, dynamic> json) {
    return UploadUrlResult(
      uploadUrl: json['uploadUrl'],
      publicUrl: json['publicUrl'],
      filePath: json['filePath'],
      expiresIn: json['expiresIn'],
    );
  }
}
