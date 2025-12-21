import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skadoosh_app/services/device_pairing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final _devicePairingService = DevicePairingService();
  final _shareIdController = TextEditingController();

  List<PairedDevice> _pairedDevices = [];
  List<PairingRequest> _pendingRequests = [];
  String? _currentUserShareId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final syncUrl = prefs.getString('sync_server_url');
    final shareId = prefs.getString('user_share_id');

    if (syncUrl != null) {
      _devicePairingService.initialize(syncUrl);
      await _refreshData();
    }

    setState(() {
      _currentUserShareId = shareId;
    });
  }

  Future<void> _refreshData() async {
    if (!_devicePairingService.isConfigured) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get paired devices
      final pairedDevices = await _devicePairingService.getPairedDevices();

      // Get pending requests
      final pendingRequests = await _devicePairingService.getPendingRequests();

      setState(() {
        _pairedDevices = pairedDevices;
        _pendingRequests = pendingRequests;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to refresh data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPairingRequest() async {
    final shareId = _shareIdController.text.trim();
    if (shareId.isEmpty) {
      _showError('Please enter a Share ID');
      return;
    }

    if (shareId == _currentUserShareId) {
      _showError('Cannot pair with yourself');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _devicePairingService.sendPairingRequest(shareId);
      if (result.success) {
        _shareIdController.clear();
        _showSuccess('Pairing request sent successfully!');
        await _refreshData();
      } else {
        _showError(result.error ?? 'Failed to send pairing request');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToRequest(String requestId, bool accept) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _devicePairingService.respondToRequest(
        requestId,
        accept ? 'accept' : 'reject',
      );

      if (result.success) {
        _showSuccess(accept ? 'Request accepted!' : 'Request rejected.');
        await _refreshData();
      } else {
        _showError(result.error ?? 'Failed to respond to request');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _copyShareId() {
    if (_currentUserShareId != null) {
      Clipboard.setData(ClipboardData(text: _currentUserShareId!));
      _showSuccess('Share ID copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Your Share ID section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Share ID',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentUserShareId ?? 'Not registered',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontFamily: 'Courier',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              IconButton(
                                onPressed: _copyShareId,
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy Share ID',
                              ),
                            ],
                          ),
                          Text(
                            'Share this ID with others to allow them to send you pairing requests.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pair new device section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pair New Device',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the Share ID of the device you want to pair with:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _shareIdController,
                                  decoration: const InputDecoration(
                                    hintText: 'username#abc123',
                                    border: OutlineInputBorder(),
                                  ),
                                  enabled: !_isLoading,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _sendPairingRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                                child: const Text('Send Request'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pending requests section
                  if (_pendingRequests.isNotEmpty) ...[
                    Text(
                      'Pending Requests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_pendingRequests.map(
                      (request) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_add),
                          title: Text('From: ${request.fromUsername}'),
                          subtitle: Text(
                            'Share ID: ${request.fromShareId}\\nDevice: ${request.fromDeviceName}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () =>
                                          _respondToRequest(request.id, false),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                                child: const Text('Reject'),
                              ),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _respondToRequest(request.id, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],

                  // Paired devices section
                  Text(
                    'Paired Devices (${_pairedDevices.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_pairedDevices.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.devices_other,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No paired devices',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Send your Share ID to other devices to start syncing notes securely.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_pairedDevices.map(
                      (device) => Card(
                        child: ListTile(
                          leading: Icon(
                            Icons
                                .phone_android, // Could be dynamic based on device type
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(device.deviceName),
                          subtitle: Text(
                            'Owner: ${device.username}\\nShare ID: ${device.shareId}',
                          ),
                          trailing: Icon(
                            Icons.sync,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    )),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _shareIdController.dispose();
    super.dispose();
  }
}
