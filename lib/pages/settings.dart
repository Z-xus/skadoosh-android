import 'package:flutter/material.dart';
import 'package:skadoosh_app/pages/sync_settings_page.dart';
import 'package:skadoosh_app/pages/device_management_page.dart';
import 'package:skadoosh_app/pages/theme_switcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final themeProvider = Provider.of<ThemeProvider>(context); // Removed as unused

    // 1. Determine Target Brightness (Light vs Dark)
    // REMOVED: Moved to ThemeSwitcherPage

    // 2. Gather ALL variants from ALL families that match the brightness
    // REMOVED: Moved to ThemeSwitcherPage

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: APPEARANCE LINK ---
            Text(
              "Appearance",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _buildSimpleActionTile(
              context,
              icon: Icons.palette_rounded,
              title: "Theme & Mode",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSwitcherPage()),
              ),
            ),

            const SizedBox(height: 40),

            // --- SECTION 3: SYSTEM ACTIONS ---
            Text(
              "System",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _buildSimpleActionTile(
              context,
              icon: Icons.devices_rounded,
              title: "Devices",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceManagementPage()),
              ),
            ),
            const SizedBox(height: 10),
            _buildSimpleActionTile(
              context,
              icon: Icons.sync_rounded,
              title: "Sync",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncSettingsPage()),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSimpleActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
