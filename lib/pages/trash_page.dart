import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Note> _trashNotes = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.animationMedium,
      vsync: this,
    );
    _fadeAnimation = FadeTransition(
      opacity: _animationController,
      child: Container(),
    ).opacity;

    _loadTrashNotes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrashNotes() async {
    final noteDatabase = Provider.of<NoteDatabase>(context, listen: false);
    final trashNotes = await noteDatabase.getTrashNotes();
    setState(() {
      _trashNotes = trashNotes;
    });
  }

  void _restoreNote(int id) {
    context.read<NoteDatabase>().restoreFromTrash(id);
    _showMessage('Note restored from trash', isSuccess: true);
    _loadTrashNotes();
  }

  void _permanentlyDeleteNote(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Note'),
        content: const Text(
          'This note will be permanently deleted and cannot be recovered. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NoteDatabase>().permanentlyDeleteNote(id);
              _showMessage('Note permanently deleted', isError: true);
              _loadTrashNotes();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _emptyTrash() {
    if (_trashNotes.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash'),
        content: Text(
          'This will permanently delete all ${_trashNotes.length} notes in trash. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final noteDatabase = Provider.of<NoteDatabase>(
                context,
                listen: false,
              );
              for (final note in _trashNotes) {
                await noteDatabase.permanentlyDeleteNote(note.id);
              }
              _showMessage('All notes permanently deleted', isError: true);
              _loadTrashNotes();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  void _cleanupOldTrash() async {
    final noteDatabase = Provider.of<NoteDatabase>(context, listen: false);
    await noteDatabase.cleanUpOldTrash();
    _showMessage('Old notes cleaned up', isSuccess: true);
    _loadTrashNotes();
  }

  void _showMessage(
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: isSuccess
            ? colorScheme.inverseSurface
            : isError
            ? colorScheme.errorContainer
            : null,
        behavior: SnackBarBehavior.floating,
        margin: DesignTokens.pageMargin,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        title: Text(
          'Trash',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_trashNotes.isNotEmpty) ...[
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: _cleanupOldTrash,
                  child: const Row(
                    children: [
                      Icon(Icons.auto_delete_rounded),
                      SizedBox(width: 12),
                      Text('Clean up old notes'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: _emptyTrash,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever_rounded,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Empty trash',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadTrashNotes,
          color: colorScheme.primary,
          child: _trashNotes.isEmpty
              ? _EmptyTrashView(theme: theme)
              : Column(
                  children: [
                    // Info banner
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusM,
                        ),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Notes are automatically deleted after 30 days',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Trash notes list
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final note = _trashNotes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _TrashNoteTile(
                                    key: ValueKey(note.id),
                                    note: note,
                                    onRestore: () => _restoreNote(note.id),
                                    onPermanentDelete: () =>
                                        _permanentlyDeleteNote(note.id),
                                  ),
                                );
                              }, childCount: _trashNotes.length),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TrashNoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  const _TrashNoteTile({
    super.key,
    required this.note,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDaysUntilDeletion(DateTime? deletedAt) {
    if (deletedAt == null) return '';
    final now = DateTime.now();
    final daysPassed = now.difference(deletedAt).inDays;
    final daysLeft = 30 - daysPassed;

    if (daysLeft <= 0) return 'Scheduled for deletion';
    if (daysLeft == 1) return 'Deletes in 1 day';
    return 'Deletes in $daysLeft days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final dateString = _formatDate(note.deletedAt);
    final deletionString = _getDaysUntilDeletion(note.deletedAt);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with trash icon and actions
            Row(
              children: [
                Icon(
                  Icons.delete_rounded,
                  size: 16,
                  color: colorScheme.error.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'In Trash',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.error.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRestore,
                  icon: Icon(
                    Icons.restore_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Restore note',
                ),
                IconButton(
                  onPressed: onPermanentDelete,
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Delete forever',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            if (note.title.isNotEmpty) ...[
              Text(
                note.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
            ],

            // Content removed for minimalistic design

            // Metadata Row: Delete Date and Time Left
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deleted $dateString',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deletionString,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.error.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTrashView extends StatelessWidget {
  final ThemeData theme;

  const _EmptyTrashView({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_rounded,
            size: 64,
            color: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            'Trash is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deleted notes will appear here for 30 days',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
