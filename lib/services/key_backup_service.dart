import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skadoosh_app/services/crypto_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for backing up and restoring encryption keys
/// This is critical for account recovery if app data is cleared
class KeyBackupService {
  static const String _backupFileName = 'skadoosh_account_backup.json';
  static const String _backupVersionKey = 'backup_version';
  static const String _currentBackupVersion = '1.0';

  /// Export account backup with all necessary keys and metadata
  /// Returns the file path where backup was saved
  Future<String> exportAccountBackup() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all account data (check multiple key names for compatibility)
    final privateKey =
        prefs.getString('user_private_key') ?? prefs.getString('private_key');
    final publicKey =
        prefs.getString('user_public_key') ?? prefs.getString('public_key');
    final fingerprint = prefs.getString('key_fingerprint');
    final deviceId =
        prefs.getString('sync_device_id') ?? prefs.getString('device_id');
    final username =
        prefs.getString('username') ??
        prefs.getString('device_pairing_username');
    final userShareId =
        prefs.getString('user_share_id') ??
        prefs.getString('device_pairing_share_id');
    final syncServerUrl = prefs.getString('sync_server_url');
    final groupName = prefs.getString('sync_group_name');

    if (privateKey == null || publicKey == null) {
      throw Exception('No account keys found. Please create an account first.');
    }

    print('📦 Creating backup with device ID: $deviceId');
    print('📦 Group name: $groupName');
    print('📦 Fingerprint: $fingerprint');

    // Create backup data structure
    final backupData = {
      _backupVersionKey: _currentBackupVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'account': {
        'username': username,
        'userShareId': userShareId,
        'deviceId': deviceId,
        'fingerprint': fingerprint,
        'groupName': groupName,
      },
      'keys': {'publicKey': publicKey, 'privateKey': privateKey},
      'server': {'syncServerUrl': syncServerUrl},
      'metadata': {'appVersion': '1.0.0', 'platform': Platform.operatingSystem},
    };

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      // Try manageExternalStorage for Android 11+
      if (Platform.isAndroid) {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          throw Exception(
            'Storage permission is required to export account backup',
          );
        }
      } else {
        throw Exception(
          'Storage permission is required to export account backup',
        );
      }
    }

    // Let user choose where to save
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Account Backup',
      fileName: _backupFileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputFile == null) {
      throw Exception('Backup cancelled by user');
    }

    // Write backup file
    final file = File(outputFile);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backupData),
    );

    // Mark that backup has been created
    await prefs.setBool('account_backup_created', true);
    await prefs.setString('last_backup_date', DateTime.now().toIso8601String());

    print('✅ Account backup saved to: ${file.path}');
    return file.path;
  }

  /// Quick export to Downloads folder (fallback if file picker fails)
  Future<String> exportToDownloads() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all account data (check multiple key names for compatibility)
    final privateKey =
        prefs.getString('user_private_key') ?? prefs.getString('private_key');
    final publicKey =
        prefs.getString('user_public_key') ?? prefs.getString('public_key');
    final fingerprint = prefs.getString('key_fingerprint');
    final deviceId =
        prefs.getString('sync_device_id') ?? prefs.getString('device_id');
    final username =
        prefs.getString('username') ??
        prefs.getString('device_pairing_username');
    final userShareId =
        prefs.getString('user_share_id') ??
        prefs.getString('device_pairing_share_id');
    final syncServerUrl = prefs.getString('sync_server_url');
    final groupName = prefs.getString('sync_group_name');

    if (privateKey == null || publicKey == null) {
      throw Exception('No account keys found. Please create an account first.');
    }

    // Create backup data
    final backupData = {
      _backupVersionKey: _currentBackupVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'account': {
        'username': username,
        'userShareId': userShareId,
        'deviceId': deviceId,
        'fingerprint': fingerprint,
        'groupName': groupName,
      },
      'keys': {'publicKey': publicKey, 'privateKey': privateKey},
      'server': {'syncServerUrl': syncServerUrl},
      'metadata': {'appVersion': '1.0.0', 'platform': Platform.operatingSystem},
    };

    // Get Downloads directory
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        downloadsDir = await getExternalStorageDirectory();
      }
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    if (downloadsDir == null) {
      throw Exception('Could not access Downloads directory');
    }

    // Create file with timestamp
    final timestamp = DateTime.now()
        .toIso8601String()
        .split('.')[0]
        .replaceAll(':', '-');
    final fileName = 'skadoosh_backup_$timestamp.json';
    final file = File(p.join(downloadsDir.path, fileName));

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backupData),
    );

    // Mark that backup has been created
    await prefs.setBool('account_backup_created', true);
    await prefs.setString('last_backup_date', DateTime.now().toIso8601String());

    print('✅ Account backup saved to Downloads: ${file.path}');
    return file.path;
  }

  /// Import and restore account from backup file
  Future<ImportResult> importAccountBackup() async {
    // Let user choose backup file
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Account Backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final file = File(result.files.first.path!);
    final backupContent = await file.readAsString();

    return await _restoreFromBackupData(backupContent);
  }

  /// Restore account from backup JSON string
  Future<ImportResult> _restoreFromBackupData(String backupJson) async {
    try {
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Validate backup version
      final version = backupData[_backupVersionKey] as String?;
      if (version == null) {
        throw Exception('Invalid backup file: missing version');
      }

      // Extract account data
      final account = backupData['account'] as Map<String, dynamic>?;
      final keys = backupData['keys'] as Map<String, dynamic>?;
      final server = backupData['server'] as Map<String, dynamic>?;

      if (keys == null || account == null) {
        throw Exception('Invalid backup file: missing required data');
      }

      // Validate keys
      final publicKey = keys['publicKey'] as String?;
      final privateKey = keys['privateKey'] as String?;

      if (publicKey == null || privateKey == null) {
        throw Exception('Invalid backup file: missing keys');
      }

      // Test that the private key can be parsed
      try {
        CryptoUtils.parsePrivateKeyFromPem(privateKey);
      } catch (e) {
        throw Exception('Invalid backup file: corrupted private key');
      }

      // Restore to SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Restore keys (save with all key name variations for compatibility)
      await prefs.setString('user_private_key', privateKey);
      await prefs.setString('user_public_key', publicKey);
      await prefs.setString('private_key', privateKey);
      await prefs.setString('public_key', publicKey);

      if (keys['fingerprint'] != null) {
        await prefs.setString('key_fingerprint', keys['fingerprint'] as String);
      }

      // Restore account info (save with all key name variations for compatibility)
      if (account['username'] != null) {
        await prefs.setString('username', account['username'] as String);
        await prefs.setString(
          'device_pairing_username',
          account['username'] as String,
        );
      }
      if (account['userShareId'] != null) {
        await prefs.setString(
          'user_share_id',
          account['userShareId'] as String,
        );
        await prefs.setString(
          'device_pairing_share_id',
          account['userShareId'] as String,
        );
      }
      if (account['deviceId'] != null) {
        // Save with both key names for compatibility
        await prefs.setString('sync_device_id', account['deviceId'] as String);
        await prefs.setString('device_id', account['deviceId'] as String);
        print('✅ Restored device ID: ${account['deviceId']}');
      }
      if (account['groupName'] != null) {
        await prefs.setString(
          'sync_group_name',
          account['groupName'] as String,
        );
        print('✅ Restored sync group: ${account['groupName']}');
      }
      if (account['fingerprint'] != null) {
        await prefs.setString(
          'key_fingerprint',
          account['fingerprint'] as String,
        );
        print('✅ Restored fingerprint: ${account['fingerprint']}');
      }
      if (account['groupName'] != null) {
        await prefs.setString(
          'sync_group_name',
          account['groupName'] as String,
        );
      }
      if (account['fingerprint'] != null) {
        await prefs.setString(
          'key_fingerprint',
          account['fingerprint'] as String,
        );
      }

      // Restore server URL (optional)
      if (server != null && server['syncServerUrl'] != null) {
        await prefs.setString(
          'sync_server_url',
          server['syncServerUrl'] as String,
        );
      }

      // Restore account info
      if (account['username'] != null) {
        await prefs.setString('username', account['username'] as String);
      }
      if (account['userShareId'] != null) {
        await prefs.setString(
          'user_share_id',
          account['userShareId'] as String,
        );
      }
      if (account['deviceId'] != null) {
        await prefs.setString('device_id', account['deviceId'] as String);
      }
      if (account['groupName'] != null) {
        await prefs.setString(
          'sync_group_name',
          account['groupName'] as String,
        );
      }
      if (account['userShareId'] != null) {
        await prefs.setString(
          'user_share_id',
          account['userShareId'] as String,
        );
      }
      if (account['deviceId'] != null) {
        await prefs.setString('device_id', account['deviceId'] as String);
      }
      if (account['groupName'] != null) {
        await prefs.setString(
          'sync_group_name',
          account['groupName'] as String,
        );
      }

      // Restore server URL (optional)
      if (server != null && server['syncServerUrl'] != null) {
        await prefs.setString(
          'sync_server_url',
          server['syncServerUrl'] as String,
        );
      }

      // Mark as restored
      await prefs.setBool('account_restored_from_backup', true);
      await prefs.setString(
        'account_restored_date',
        DateTime.now().toIso8601String(),
      );

      print('✅ Account successfully restored from backup');

      return ImportResult(
        success: true,
        username: account['username'] as String?,
        userShareId: account['userShareId'] as String?,
        fingerprint: keys['fingerprint'] as String?,
      );
    } catch (e) {
      print('❌ Failed to restore account: $e');
      return ImportResult(success: false, error: e.toString());
    }
  }

  /// Check if user has created a backup
  Future<bool> hasCreatedBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('account_backup_created') ?? false;
  }

  /// Get last backup date
  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('last_backup_date');
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Check if account was restored from backup
  Future<bool> wasRestoredFromBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('account_restored_from_backup') ?? false;
  }
}

/// Result of importing account backup
class ImportResult {
  final bool success;
  final String? username;
  final String? userShareId;
  final String? fingerprint;
  final String? error;

  ImportResult({
    required this.success,
    this.username,
    this.userShareId,
    this.fingerprint,
    this.error,
  });
}
