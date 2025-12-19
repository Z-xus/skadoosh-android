import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skadoosh_app/services/crypto_utils.dart';
import 'package:http/http.dart' as http;

class KeyManagementPage extends StatefulWidget {
  const KeyManagementPage({super.key});

  @override
  State<KeyManagementPage> createState() => _KeyManagementPageState();
}

class _KeyManagementPageState extends State<KeyManagementPage> {
  final _groupNameController = TextEditingController();
  final _importKeyController = TextEditingController();

  KeyPairInfo? _currentKeyPair;
  String? _serverUrl;
  String? _currentGroup;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = prefs.getString('sync_server_url');
    });
  }

  Future<void> _loadExistingKey() async {
    final prefs = await SharedPreferences.getInstance();
    final keyData = prefs.getString('user_key_pair');
    final groupName = prefs.getString('sync_group_name');

    if (keyData != null) {
      try {
        final keyMap = jsonDecode(keyData) as Map<String, dynamic>;
        setState(() {
          _currentKeyPair = KeyPairInfo.fromMap(keyMap);
          _currentGroup = groupName;
        });
      } catch (e) {
        print('Error loading key: $e');
      }
    }
  }

  Future<void> _saveKeyPair(KeyPairInfo keyPair, String groupName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_key_pair', jsonEncode(keyPair.toMap()));
    await prefs.setString('sync_group_name', groupName);
    await prefs.setString('key_fingerprint', keyPair.fingerprint);
  }

  Future<void> _generateNewKey() async {
    if (_groupNameController.text.trim().isEmpty) {
      _showMessage('Please enter a group name', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Generating key pair...';
    });

    try {
      // Generate new RSA key pair
      final keyPair = CryptoUtils.generateRSAKeyPair();
      final keyPairInfo = KeyPairInfo.fromKeyPair(keyPair);

      // Save locally
      await _saveKeyPair(keyPairInfo, _groupNameController.text.trim());

      // Join sync group on server
      if (_serverUrl != null) {
        await _joinSyncGroup(keyPairInfo, _groupNameController.text.trim());
      }

      setState(() {
        _currentKeyPair = keyPairInfo;
        _currentGroup = _groupNameController.text.trim();
        _message = 'Key generated successfully!';
      });
    } catch (e) {
      _showMessage('Failed to generate key: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importKey() async {
    if (_importKeyController.text.trim().isEmpty ||
        _groupNameController.text.trim().isEmpty) {
      _showMessage(
        'Please enter both private key and group name',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Importing key...';
    });

    try {
      KeyPairInfo keyPairInfo;
      final inputText = _importKeyController.text.trim();

      // Validate the input format
      if (inputText.startsWith('-----BEGIN PRIVATE KEY-----')) {
        // Handle PEM format private key
        _showMessage(
          'PEM format detected. For multi-device sync, please use the "Export Key" button from another device to get the proper JSON format.',
          isError: true,
        );
        return;
      } else {
        // Handle JSON format (original expected format)
        try {
          // Validate JSON structure first
          final keyData = jsonDecode(inputText) as Map<String, dynamic>;

          // Check for required fields
          if (!keyData.containsKey('publicKey') ||
              !keyData.containsKey('privateKey') ||
              !keyData.containsKey('fingerprint')) {
            _showMessage(
              'Invalid key format. Missing required fields: publicKey, privateKey, or fingerprint.',
              isError: true,
            );
            return;
          }

          // Validate that the values are not null
          if (keyData['publicKey'] == null ||
              keyData['privateKey'] == null ||
              keyData['fingerprint'] == null) {
            _showMessage(
              'Invalid key format. Key fields cannot be null.',
              isError: true,
            );
            return;
          }

          keyPairInfo = KeyPairInfo.fromMap(keyData);
        } catch (e) {
          print('Key import error: $e');
          _showMessage(
            'Invalid key format. Please paste the key exactly as exported from another device. Error: $e',
            isError: true,
          );
          return;
        }
      }

      // Save locally
      await _saveKeyPair(keyPairInfo, _groupNameController.text.trim());

      // Join sync group on server
      if (_serverUrl != null) {
        try {
          await _joinSyncGroup(keyPairInfo, _groupNameController.text.trim());
        } catch (e) {
          // Non-fatal error - key is saved locally but server registration failed
          print('Server registration failed: $e');
          _showMessage(
            'Key imported locally, but server registration failed: $e\nYou can configure the server later.',
            isError: false,
          );
        }
      }

      setState(() {
        _currentKeyPair = keyPairInfo;
        _currentGroup = _groupNameController.text.trim();
        _message = 'Key imported successfully!';
      });

      _importKeyController.clear();
    } catch (e) {
      print('Import key error: $e');
      _showMessage('Failed to import key: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinSyncGroup(KeyPairInfo keyPair, String groupName) async {
    if (_serverUrl == null) return;

    final response = await http.post(
      Uri.parse('$_serverUrl/api/auth/join-group'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'groupName': groupName,
        'publicKey': keyPair.publicKeyPem,
        'deviceId':
            'flutter_device', // You might want to generate a unique device ID
        'deviceName': 'Flutter App',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to join sync group: ${response.body}');
    }
  }

  Future<void> _exportKey() async {
    if (_currentKeyPair == null) return;

    final keyData = jsonEncode(_currentKeyPair!.toMap());
    await Clipboard.setData(ClipboardData(text: keyData));
    _showMessage('Private key copied to clipboard!');
  }

  Future<void> _exportPublicKey() async {
    if (_currentKeyPair == null) return;

    final publicKeyData = jsonEncode({
      'publicKey': _currentKeyPair!.publicKeyPem,
      'fingerprint': _currentKeyPair!.fingerprint,
      'groupName': _currentGroup,
    });

    await Clipboard.setData(ClipboardData(text: publicKeyData));
    _showMessage('Public key info copied to clipboard!');
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Key Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Key Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (_currentKeyPair != null) ...[
                      _buildStatusRow('Status', 'Key Configured', Colors.green),
                      _buildStatusRow(
                        'Fingerprint',
                        _currentKeyPair!.fingerprint,
                        Colors.blue,
                      ),
                      if (_currentGroup != null)
                        _buildStatusRow(
                          'Sync Group',
                          _currentGroup!,
                          Colors.blue,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportKey,
                              icon: const Icon(Icons.download),
                              label: const Text('Export Private Key'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportPublicKey,
                              icon: const Icon(Icons.share),
                              label: const Text('Share Public Key'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildStatusRow(
                        'Status',
                        'No Key Configured',
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Generate a new key or import an existing one to get started.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generate New Key
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate New Key',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Sync Group Name',
                        hintText: 'e.g., family-notes, work-team',
                        border: OutlineInputBorder(),
                        helperText: 'Choose a unique name for your sync group',
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateNewKey,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.key),
                        label: const Text('Generate New Key Pair'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Import Existing Key
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Existing Key',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _importKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Private Key Data',
                        hintText: 'Paste exported key data here',
                        border: OutlineInputBorder(),
                        helperText:
                            'Paste the exported key from another device',
                      ),
                      maxLines: 3,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _importKey,
                        icon: const Icon(Icons.upload),
                        label: const Text('Import Key'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Key-Based Sync Works',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🔑 Generate Keys: Create a new RSA key pair for secure authentication\n\n'
                      '👥 Sync Groups: Choose a group name to sync with specific people\n\n'
                      '📤 Share: Export your private key to sync on multiple devices\n\n'
                      '🔐 Security: Private keys never leave your devices, ensuring maximum security\n\n'
                      '🎯 Isolation: Different groups are completely isolated from each other',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(_message!, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _importKeyController.dispose();
    super.dispose();
  }
}
