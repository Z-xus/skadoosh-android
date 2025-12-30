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

  String _getFriendlyDeviceName(String deviceName) {
    if (deviceName.toLowerCase().contains('sdk built for') ||
        deviceName.toLowerCase().contains('google sdk')) {
      return 'Android';
    }
    return deviceName;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
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
                  // Your Share ID section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.4),
                          Theme.of(context).colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Share ID',
                          style: TextStyle(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // The ID Display Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                _currentUserShareId ?? 'Not registered',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              IconButton.filledTonal(
                                onPressed: _copyShareId,
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                tooltip: 'Copy Share ID',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Share this ID with others to pair devices securely.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pair new device section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(
                        24,
                      ), // Softer, modern rounding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pair New Device',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _shareIdController,
                                decoration: InputDecoration(
                                  hintText: 'username#abc123',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.withOpacity(0.6),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide
                                        .none, // Removes the harsh black line
                                  ),
                                ),
                                enabled: !_isLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              // Material 3 component for a cleaner look
                              onPressed: _isLoading
                                  ? null
                                  : _sendPairingRequest,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: const Text('Pair'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pending requests section
                  if (_pendingRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Pending Requests',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    ...(_pendingRequests.map(
                      (request) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar/Icon Circle
                            CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person_outline,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Info Section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.fromUsername,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${request.fromShareId} • ${_getFriendlyDeviceName(request.fromDeviceName)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontFamily:
                                              'monospace', // Gives it that tech/ID look
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _respondToRequest(
                                          request.id,
                                          false,
                                        ),
                                  icon: const Icon(Icons.close),
                                  color: Theme.of(context).colorScheme.error,
                                  tooltip: 'Reject',
                                ),
                                const SizedBox(width: 4),
                                IconButton.filled(
                                  // Material 3 filled icon button
                                  onPressed: _isLoading
                                      ? null
                                      : () =>
                                            _respondToRequest(request.id, true),
                                  icon: const Icon(Icons.check),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  tooltip: 'Accept',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],

                  //     (device) => Card(
                  //       child: ListTile(
                  //         leading: Icon(
                  //           Icons
                  //               .phone_android, // Could be dynamic based on device type
                  //           color: Theme.of(context).colorScheme.primary,
                  //         ),
                  //         title: Text(device.deviceName),
                  //         subtitle: Text(
                  //           'Owner: ${device.username}\\nShare ID: ${device.shareId}',
                  //         ),
                  //         trailing: Icon(
                  //           Icons.sync,
                  //           color: Theme.of(context).colorScheme.tertiary,
                  //         ),
                  //         isThreeLine: true,
                  //       ),
                  //     ),
                  //   )),
                  // Paired Devices Header with Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Paired Devices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(999), // pill
                          ),
                          child: Text(
                            _pairedDevices.length.toString(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_pairedDevices.isEmpty)
                    // Minimalist Empty State
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sensors_off_rounded,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No paired devices',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sync your notes by sharing your ID.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.4),
                                ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_pairedDevices.map(
                      (device) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Device Icon Container
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.phone_android_rounded,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Device Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getFriendlyDeviceName(device.deviceName),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Owner: ${device.username}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    device.shareId,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontFamily: 'monospace',
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Status/Action
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sync_rounded,
                                size: 18,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
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
