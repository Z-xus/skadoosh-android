import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:skadoosh_app/components/note_settings.dart';
import 'package:skadoosh_app/models/note.dart';

class NoteTile extends StatelessWidget {
  final String text;
  final void Function()? onEditPressed;
  final void Function()? onDeletePressed;
  final Note? note;

  const NoteTile({
    super.key,
    required this.text,
    required this.onEditPressed,
    required this.onDeletePressed,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.only(bottom: 10, left: 25, right: 25),
      child: ListTile(
        title: Text(text),
        subtitle: note != null ? _buildSyncStatus(context) : null,
        trailing: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.more_vert),
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

  Widget? _buildSyncStatus(BuildContext context) {
    if (note == null) return null;

    final bool needsSync = note!.needsSync;
    final bool hasSyncInfo =
        note!.serverId != null || note!.lastSyncedAt != null;

    if (!needsSync && !hasSyncInfo) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
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
                : note!.serverId != null
                ? 'Synced'
                : 'Local only',
            style: TextStyle(
              fontSize: 10,
              color: needsSync ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
