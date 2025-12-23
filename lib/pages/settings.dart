import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';
import 'package:skadoosh_app/theme/catppuccin_colors.dart';
import 'package:skadoosh_app/pages/sync_settings_page.dart';
import 'package:skadoosh_app/pages/device_management_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Settings",
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: DesignTokens.pageMargin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Selection Section
            _buildSectionHeader(context, "Appearance"),
            SizedBox(height: DesignTokens.spaceS.top),
            _buildThemeSelector(context),

            SizedBox(height: DesignTokens.spaceL.top),

            // Sync & Device Section
            _buildSectionHeader(context, "Sync & Devices"),
            SizedBox(height: DesignTokens.spaceS.top),

            // Device Management
            _buildSettingCard(
              context,
              icon: Icons.devices_rounded,
              title: "Device Management",
              subtitle: "Manage paired devices and sync",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceManagementPage(),
                ),
              ),
            ),

            SizedBox(height: DesignTokens.spaceS.top),

            // Sync Settings
            _buildSettingCard(
              context,
              icon: Icons.sync_rounded,
              title: "Sync Settings",
              subtitle: "Configure note synchronization",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SyncSettingsPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          padding: DesignTokens.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_rounded,
                    size: DesignTokens.iconSizeM,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: DesignTokens.spaceS.left),
                  Text(
                    "Theme",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceS.top),
              Text(
                "Choose your preferred Catppuccin flavor",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: DesignTokens.spaceM.top),

              // Theme flavor grid
              Wrap(
                spacing: DesignTokens.spaceS.left,
                runSpacing: DesignTokens.spaceS.top,
                children: themeProvider.availableFlavors.map((flavor) {
                  return _buildThemeFlavorTile(context, themeProvider, flavor);
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeFlavorTile(
    BuildContext context,
    ThemeProvider themeProvider,
    String flavor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = themeProvider.currentFlavor == flavor;
    final flavorInfo = themeProvider.getFlavorInfo(flavor);
    final palette = CatppuccinColors.getPalette(flavor);

    return GestureDetector(
      onTap: () => themeProvider.setFlavor(flavor),
      child: AnimatedContainer(
        duration: DesignTokens.animationMedium,
        curve: DesignTokens.animationCurveStandard,
        width: 140,
        padding: DesignTokens.spaceS,
        decoration: BoxDecoration(
          color: isSelected
              ? palette.mauve.withValues(alpha: 0.1)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: isSelected
                ? palette.mauve
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color preview row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Color palette preview
                Row(
                  children: [
                    _buildColorDot(palette.mauve),
                    SizedBox(width: 2),
                    _buildColorDot(palette.blue),
                    SizedBox(width: 2),
                    _buildColorDot(palette.green),
                    SizedBox(width: 2),
                    _buildColorDot(palette.yellow),
                  ],
                ),
                // Selection indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: DesignTokens.iconSizeS,
                    color: palette.mauve,
                  ),
              ],
            ),

            SizedBox(height: DesignTokens.spaceXS.top),

            // Flavor name
            Text(
              flavorInfo['name'] as String,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? palette.text : colorScheme.onSurface,
              ),
            ),

            // Flavor description
            Text(
              flavorInfo['description'] as String,
              style: textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? palette.subtext0
                    : colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: DesignTokens.cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: DesignTokens.spaceS,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  icon,
                  size: DesignTokens.iconSizeM,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM.left),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: DesignTokens.iconSizeM,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
