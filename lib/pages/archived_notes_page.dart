import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/pages/edit_note_page.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class ArchivedNotesPage extends StatefulWidget {
  const ArchivedNotesPage({super.key});

  @override
  State<ArchivedNotesPage> createState() => _ArchivedNotesPageState();
}

class _ArchivedNotesPageState extends State<ArchivedNotesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Note> _archivedNotes = [];

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

    _loadArchivedNotes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadArchivedNotes() async {
    final noteDatabase = Provider.of<NoteDatabase>(context, listen: false);
    final archivedNotes = await noteDatabase.getArchivedNotes();
    setState(() {
      _archivedNotes = archivedNotes;
    });
  }

  void _updateNote(Note note) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => EditNotePage(note: note),
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
    ).then((_) => _loadArchivedNotes());
  }

  void _unarchiveNote(int id) {
    context.read<NoteDatabase>().unarchiveNote(id);
    _showMessage('Note restored from archive', isSuccess: true);
    _loadArchivedNotes();
  }

  void _moveNoteToTrash(int id) {
    context.read<NoteDatabase>().moveToTrash(id);
    _showMessage('Note moved to trash', isSuccess: true);
    _loadArchivedNotes();
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
          'Archived Notes',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadArchivedNotes,
          color: colorScheme.primary,
          child: _archivedNotes.isEmpty
              ? _EmptyArchivedNotesView(theme: theme)
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final note = _archivedNotes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _ArchivedNoteTile(
                              key: ValueKey(note.id),
                              note: note,
                              onTap: () => _updateNote(note),
                              onUnarchive: () => _unarchiveNote(note.id),
                              onDelete: () => _moveNoteToTrash(note.id),
                            ),
                          );
                        }, childCount: _archivedNotes.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ArchivedNoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const _ArchivedNoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onUnarchive,
    required this.onDelete,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final dateString = _formatDate(note.archivedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with archive icon and actions
              Row(
                children: [
                  Icon(
                    Icons.archive_rounded,
                    size: 16,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Archived',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onUnarchive,
                    icon: Icon(
                      Icons.unarchive_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'Restore from archive',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Move to trash',
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
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
              ],

              // Content removed for minimalistic design

              // Metadata Row: Archive Date
              Row(
                children: [
                  Text(
                    'Archived $dateString',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    note.needsSync
                        ? Icons.cloud_upload_rounded
                        : Icons.cloud_done_rounded,
                    size: 14,
                    color: note.needsSync
                        ? colorScheme.primary.withValues(alpha: 0.6)
                        : colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyArchivedNotesView extends StatelessWidget {
  final ThemeData theme;

  const _EmptyArchivedNotesView({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_rounded,
            size: 64,
            color: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            'No archived notes',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Archived notes will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
