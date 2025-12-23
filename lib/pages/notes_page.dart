import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/components/drawer.dart';
// Note: We are replacing the external NoteTile with a local _MinimalNoteTile
// to fix the layout issues directly in this file.
// import 'package:skadoosh_app/components/note_tile.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/key_based_sync_service.dart';
import 'package:skadoosh_app/pages/edit_note_page.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  KeyBasedSyncService? _syncService;
  bool _isSyncing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _initializeData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _readNotes();
    await _initializeSyncService();
  }

  Future<void> _initializeSyncService() async {
    try {
      final noteDatabase = Provider.of<NoteDatabase>(context, listen: false);
      _syncService = KeyBasedSyncService(noteDatabase);
      await _syncService!.initialize();
    } catch (e) {
      debugPrint('Failed to initialize sync service: $e');
    }
  }

  void _createNote() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const EditNotePage(),
        transitionDuration: DesignTokens.animationMedium,
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
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

  void _readNotes() {
    context.read<NoteDatabase>().fetchNotes();
  }

  Future<void> _performSync() async {
    if (_syncService == null || _isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final syncStatus = await _syncService!.getSyncStatus();
      if (!syncStatus.isConfigured) {
        _showMessage('Sync not configured. Please configure sync in Settings.');
        return;
      }

      final result = await _syncService!.sync();
      if (result.success) {
        _showMessage(
          'Sync completed! Pushed: ${result.pushedNotes}, Pulled: ${result.pulledNotes}',
          isSuccess: true,
        );
        _readNotes();
      } else {
        _showMessage('Sync failed: ${result.error}', isError: true);
      }
    } catch (e) {
      _showMessage('Sync failed: $e', isError: true);
    } finally {
      setState(() => _isSyncing = false);
    }
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
    );
  }

  void _moveNoteToTrash(int id) {
    context.read<NoteDatabase>().moveToTrash(id);
    _showMessage('Note moved to trash', isSuccess: true);
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
          'Notes',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Semantics(
            label: _isSyncing
                ? 'Syncing notes in progress'
                : 'Sync notes with server',
            button: true,
            child: IconButton(
              onPressed: _isSyncing ? null : _performSync,
              icon: _isSyncing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.sync_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
              tooltip: _isSyncing ? 'Syncing...' : 'Sync notes',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: colorScheme.surface,
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        elevation: 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _performSync,
          color: colorScheme.primary,
          child: Consumer<NoteDatabase>(
            builder: (context, noteDatabase, child) {
              final notes = noteDatabase.currentNotes;

              if (notes.isEmpty) {
                return _EmptyNotesView(onCreateNote: _createNote, theme: theme);
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final note = notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _MinimalNoteTile(
                            key: ValueKey(note.id),
                            note: note,
                            onTap: () => _updateNote(note),
                            onDelete: () => _moveNoteToTrash(note.id),
                          ),
                        );
                      }, childCount: notes.length),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A local, optimized tile widget to ensure strict minimalist design
class _MinimalNoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MinimalNoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  // Helper to format date cleanly
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

    // Use the actual updatedAt from your model
    final dateString = _formatDate(note.updatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        // The Border: Subtle, single distinct line
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
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

              // Content Preview - CHANGED from note.content to note.body
              if (note.body.isNotEmpty) ...[
                Text(
                  note.body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Metadata Row: Date & Sync on ONE line
              Row(
                children: [
                  // Date
                  Text(
                    dateString,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  // Sync Status Indicator (Compact)
                  // Using needsSync logic from your model
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

// Minimalist Empty State
class _EmptyNotesView extends StatelessWidget {
  final VoidCallback onCreateNote;
  final ThemeData theme;

  const _EmptyNotesView({required this.onCreateNote, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 64,
            color: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onCreateNote,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
