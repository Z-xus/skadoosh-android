import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:skadoosh_app/components/note_settings.dart';
import 'package:skadoosh_app/models/note.dart';

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

  @override
  Widget build(BuildContext context) {
    final bodyPreview = _getBodyPreview();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.only(bottom: 10, left: 25, right: 25),
      child: ListTile(
        title: Text(
          note.title.isNotEmpty ? note.title : 'Untitled',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bodyPreview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                bodyPreview,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.inversePrimary.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_shouldShowSyncStatus()) ...[
              const SizedBox(height: 8),
              _buildSyncStatus(context),
            ],
          ],
        ),
        trailing: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () => showPopover(
              context: context,
              width: 100,
              height: 100,
              backgroundColor: Theme.of(context).colorScheme.surface,
              bodyBuilder: (context) => NoteSettings(
                onEditTap: onEditPressed,
                onDeleteTap: onDeletePressed,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowSyncStatus() {
    final bool needsSync = note.needsSync;
    final bool hasSyncInfo = note.serverId != null || note.lastSyncedAt != null;
    return needsSync || hasSyncInfo;
  }

  Widget _buildSyncStatus(BuildContext context) {
    final bool needsSync = note.needsSync;

    return Row(
      children: [
        Icon(
          needsSync ? Icons.sync_problem : Icons.sync,
          size: 12,
          color: needsSync ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          needsSync
              ? 'Needs sync'
              : note.serverId != null
              ? 'Synced'
              : 'Local only',
          style: TextStyle(
            fontSize: 10,
            color: needsSync ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }
}
