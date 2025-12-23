import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:skadoosh_app/components/note_settings.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';
import 'package:intl/intl.dart';

class NoteTile extends StatelessWidget {
  final void Function()? onEditPressed;
  final void Function()? onDeletePressed;
  final Note note;

  const NoteTile({
    super.key,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.note,
  });

  String _getBodyPreview() {
    if (note.body.isEmpty) return '';

    // Remove markdown syntax for preview
    final cleanBody = note.body
        .replaceAll(RegExp(r'[#*_\[\]`]'), '') // Remove markdown characters
        .replaceAll(RegExp(r'\n+'), ' ') // Replace newlines with spaces
        .trim();

    // Limit to 100 characters
    if (cleanBody.length <= 100) return cleanBody;
    return '${cleanBody.substring(0, 100)}...';
  }

  /// Format timestamp for display - shows relative time for recent notes
  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // For older notes, show the actual date
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  /// Get the appropriate timestamp to display (prioritize updatedAt)
  String _getDisplayTimestamp() {
    final updated = note.updatedAt;
    final created = note.createdAt;

    if (updated != null && created != null) {
      // If updated significantly after creation, show "Updated X ago"
      final timeDiff = updated.difference(created);
      if (timeDiff.inMinutes > 5) {
        return 'Updated ${_formatTimestamp(updated)}';
      }
    }

    // For new notes or no significant update, show creation time
    return _formatTimestamp(created ?? updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bodyPreview = _getBodyPreview();

    return Container(
      margin: DesignTokensSpacing.listItem.copyWith(
        bottom: DesignTokens.spaceS.top,
      ),
      child: Material(
        elevation: DesignTokens.elevationS,
        color: colorScheme.surfaceContainerLow,
        borderRadius: DesignTokensRadius.medium,
        child: InkWell(
          onTap: onEditPressed,
          borderRadius: DesignTokensRadius.medium,
          child: Container(
            padding: DesignTokens.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Note title
                          Text(
                            note.title.isNotEmpty ? note.title : 'Untitled',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Body preview
                          if (bodyPreview.isNotEmpty) ...[
                            SizedBox(height: DesignTokens.spaceXS.top),
                            Text(
                              bodyPreview,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Timestamp with icon and subtle styling
                          SizedBox(height: DesignTokens.spaceXS.top),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: DesignTokens.iconSizeXS,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              SizedBox(width: DesignTokens.spaceXS.left),
                              Text(
                                _getDisplayTimestamp(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu button with proper touch target
                    SizedBox(
                      width: DesignTokens.touchTargetComfortableSize,
                      height: DesignTokens.touchTargetComfortableSize,
                      child: Semantics(
                        label:
                            'More options for ${note.title.isNotEmpty ? note.title : "untitled note"}',
                        button: true,
                        child: IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            size: DesignTokens.iconSizeM,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _showNoteMenu(context),
                          tooltip: 'More options',
                        ),
                      ),
                    ),
                  ],
                ),

                // Sync status indicator
                if (_shouldShowSyncStatus()) ...[
                  SizedBox(height: DesignTokens.spaceS.top),
                  _buildSyncStatus(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteMenu(BuildContext context) {
    showPopover(
      context: context,
      width: 120,
      height: 100,
      backgroundColor: Theme.of(context).colorScheme.surface,
      radius: DesignTokens.radiusM,
      bodyBuilder: (context) =>
          NoteSettings(onEditTap: onEditPressed, onDeleteTap: onDeletePressed),
    );
  }

  bool _shouldShowSyncStatus() {
    final bool needsSync = note.needsSync;
    final bool hasSyncInfo = note.serverId != null || note.lastSyncedAt != null;
    return needsSync || hasSyncInfo;
  }

  Widget _buildSyncStatus(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool needsSync = note.needsSync;

    final statusColor = needsSync ? colorScheme.error : colorScheme.tertiary;

    final statusIcon = needsSync
        ? Icons.sync_problem_rounded
        : Icons.check_circle_rounded;

    final statusText = needsSync
        ? 'Needs sync'
        : note.serverId != null
        ? 'Synced'
        : 'Local only';

    return Container(
      padding: DesignTokens.spaceVerticalXS.copyWith(
        left: DesignTokens.spaceS.left,
        right: DesignTokens.spaceS.right,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: statusText,
            child: Icon(
              statusIcon,
              size: DesignTokens.iconSizeS,
              color: statusColor,
            ),
          ),
          SizedBox(width: DesignTokens.spaceXS.left),
          Text(
            statusText,
            style: textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
