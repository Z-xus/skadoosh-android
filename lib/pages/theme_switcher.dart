import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:skadoosh_app/theme/theme_registry.dart' as registry;
import 'package:skadoosh_app/theme/base/theme_family.dart';
import 'package:skadoosh_app/theme/theme.dart';

class ThemeSwitcherPage extends StatefulWidget {
  const ThemeSwitcherPage({super.key});

  @override
  State<ThemeSwitcherPage> createState() => _ThemeSwitcherPageState();
}

class _ThemeSwitcherPageState extends State<ThemeSwitcherPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // 1. Determine Target Brightness (Light vs Dark)
    final isDark =
        themeProvider.mode == registry.AppThemeMode.dark ||
        (themeProvider.mode == registry.AppThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final targetBrightness = isDark ? Brightness.dark : Brightness.light;

    // 2. Gather ALL variants from ALL families that match the brightness
    final List<ThemeConfig> visibleConfigs = [];
    for (final family in themeProvider.availableFamilies) {
      final variants = themeProvider.getVariantsForFamily(family);
      for (final variant in variants) {
        if (variant.brightness == targetBrightness) {
          visibleConfigs.add(ThemeConfig(family: family, variant: variant));
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Appearance",
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
            // --- SECTION 1: MODE TOGGLE ---
            _buildModeSegmentedControl(context, themeProvider),

            const SizedBox(height: 32),

            // --- SECTION 2: THEME GRID (2 PER ROW) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDark ? "Dark Palettes" : "Light Palettes",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // Badge count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${visibleConfigs.length}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // TWO ITEMS PER ROW
                childAspectRatio: 1.15,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: visibleConfigs.length,
              itemBuilder: (context, index) {
                final config = visibleConfigs[index];
                final isSelected =
                    themeProvider.selectedConfig.family == config.family &&
                    themeProvider.selectedConfig.variant == config.variant;

                // Dynamically fetch colors for the dots
                final previewTheme = AppTheme.getTheme(config);
                final dotColors = [
                  previewTheme.scaffoldBackgroundColor, // Base
                  previewTheme.cardTheme.color ??
                      previewTheme.colorScheme.surface, // Surface
                  previewTheme.colorScheme.primary, // Accent 1
                  previewTheme.colorScheme.secondary, // Accent 2
                ];

                return _buildGridThemeCard(
                  context,
                  config,
                  dotColors,
                  isSelected,
                  () => themeProvider.setConfiguration(config),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildGridThemeCard(
    BuildContext context,
    ThemeConfig config,
    List<Color> dotColors,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // Active state gets a colored background, inactive is generic surface
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Icon
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.palette_outlined,
              size: 26,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 10),

            // 2. Title & Family Name
            Text(
              config.variant.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            Text(
              config.family.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                    : colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 12),

            // 3. The 4 Color Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dotColors
                  .map(
                    (c) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSegmentedControl(
    BuildContext context,
    ThemeProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final mode = provider.mode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildSegmentBtn(
            context,
            "Light",
            Icons.wb_sunny_rounded,
            mode == registry.AppThemeMode.light,
            () => provider.setMode(registry.AppThemeMode.light),
          ),
          _buildSegmentBtn(
            context,
            "Dark",
            Icons.dark_mode_rounded,
            mode == registry.AppThemeMode.dark,
            () => provider.setMode(registry.AppThemeMode.dark),
          ),
          _buildSegmentBtn(
            context,
            "Auto",
            Icons.auto_awesome_rounded,
            mode == registry.AppThemeMode.system,
            () => provider.setMode(registry.AppThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
