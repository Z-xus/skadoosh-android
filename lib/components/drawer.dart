import 'package:flutter/material.dart';
import 'package:skadoosh_app/components/drawer_tile.dart';
import 'package:skadoosh_app/pages/settings.dart';
import 'package:skadoosh_app/pages/device_management_page.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      elevation: DesignTokens.elevationM,
      child: Column(
        children: [
          // Enhanced drawer header
          Container(
            width: double.infinity,
            padding: DesignTokens.pageMargin.copyWith(
              top: MediaQuery.of(context).padding.top + DesignTokens.spaceL.top,
              bottom: DesignTokens.spaceL.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(DesignTokens.radiusL),
                bottomRight: Radius.circular(DesignTokens.radiusL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App icon
                Container(
                  padding: DesignTokens.spaceM,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: DesignTokens.iconSizeXL,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),

                SizedBox(height: DesignTokens.spaceM.top),

                // App name
                Text(
                  'Skadoosh',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: DesignTokens.spaceXS.top),

                // App tagline
                Text(
                  'Secure note synchronization',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Navigation items
          Padding(
            padding: DesignTokens.spaceVerticalL.copyWith(
              left: DesignTokens.spaceM.left,
              right: DesignTokens.spaceM.right,
            ),
            child: Column(
              children: [
                // Notes tile - current page
                DrawerTile(
                  title: "Notes",
                  leading: const Icon(Icons.note_rounded),
                  onTap: () => Navigator.pop(context),
                  isSelected: true,
                ),

                SizedBox(height: DesignTokens.spaceXS.top),

                // Device management tile
                DrawerTile(
                  title: "Device Management",
                  leading: const Icon(Icons.devices_rounded),
                  onTap: () =>
                      _navigateToPage(context, const DeviceManagementPage()),
                ),

                SizedBox(height: DesignTokens.spaceXS.top),

                // Settings tile
                DrawerTile(
                  title: "Settings",
                  leading: const Icon(Icons.settings_rounded),
                  onTap: () => _navigateToPage(context, const SettingsPage()),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Footer
          Container(
            padding: DesignTokens.pageMargin,
            child: Column(
              children: [
                Divider(color: colorScheme.outlineVariant),
                SizedBox(height: DesignTokens.spaceS.top),
                Row(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: DesignTokens.spaceS.left),
                    Expanded(
                      child: Text(
                        'End-to-end encrypted',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spaceS.top),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer first
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => page,
        transitionDuration: DesignTokens.animationMedium,
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: DesignTokens.animationCurveEmphasized,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }
}
