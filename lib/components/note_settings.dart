import 'package:flutter/material.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class NoteSettings extends StatelessWidget {
  final void Function()? onEditTap;
  final void Function()? onDeleteTap;

  const NoteSettings({
    super.key,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: DesignTokens.spaceVerticalXS,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit option
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onEditTap?.call();
                },
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                child: Container(
                  padding: DesignTokens.spaceM.copyWith(
                    top: DesignTokens.spaceS.top,
                    bottom: DesignTokens.spaceS.bottom,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: DesignTokens.iconSizeM,
                        color: colorScheme.onSurface,
                      ),
                      SizedBox(width: DesignTokens.spaceS.left),
                      Text(
                        'Edit',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Delete option
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onDeleteTap?.call();
                },
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                child: Container(
                  padding: DesignTokens.spaceM.copyWith(
                    top: DesignTokens.spaceS.top,
                    bottom: DesignTokens.spaceS.bottom,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        size: DesignTokens.iconSizeM,
                        color: colorScheme.error,
                      ),
                      SizedBox(width: DesignTokens.spaceS.left),
                      Text(
                        'Delete',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
