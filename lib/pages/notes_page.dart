import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/components/drawer.dart';
import 'package:skadoosh_app/components/note_tile.dart';
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
        actions: [
          // Sync button with accessibility
          Semantics(
            label: _isSyncing
                ? 'Syncing notes in progress'
                : 'Sync notes with server',
            button: true,
            child: IconButton(
              onPressed: _isSyncing ? null : _performSync,
              icon: _isSyncing
                  ? SizedBox(
                      width: DesignTokens.iconSizeM,
                      height: DesignTokens.iconSizeM,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.sync_rounded,
                      color: colorScheme.onSurface,
                      size: DesignTokens.iconSizeL,
                    ),
              tooltip: _isSyncing ? 'Syncing...' : 'Sync notes',
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      drawer: const MyDrawer(),
      floatingActionButton: Semantics(
        label: 'Create new note',
        button: true,
        child: FloatingActionButton(
          onPressed: _createNote,
          heroTag: 'create_note',
          tooltip: 'Create note',
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _performSync,
          color: colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerHigh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Page header with proper typography
              SliverToBoxAdapter(
                child: Container(
                  padding: DesignTokens.pageMargin.copyWith(
                    top: DesignTokens.spaceL.top,
                    bottom: DesignTokens.spaceM.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main heading with proper hierarchy
                      Text(
                        'Notes',
                        style: textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      // Sync status indicator
                      if (_isSyncing) ...[
                        SizedBox(height: DesignTokens.spaceM.top),
                        _SyncStatusIndicator(theme: theme),
                      ],
                    ],
                  ),
                ),
              ),

              // Notes list or empty state
              Consumer<NoteDatabase>(
                builder: (context, noteDatabase, child) {
                  final notes = noteDatabase.currentNotes;

                  if (notes.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyNotesView(
                        onCreateNote: _createNote,
                        theme: theme,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: DesignTokens.spaceHorizontalM,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final note = notes[index];
                        return NoteTile(
                          key: ValueKey(note.id),
                          note: note,
                          onEditPressed: () => _updateNote(note),
                          onDeletePressed: () => _moveNoteToTrash(note.id),
                        );
                      }, childCount: notes.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sync status widget
class _SyncStatusIndicator extends StatelessWidget {
  final ThemeData theme;

  const _SyncStatusIndicator({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: DesignTokens.cardPadding.copyWith(
        top: DesignTokens.spaceS.top,
        bottom: DesignTokens.spaceS.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: DesignTokens.iconSizeS,
            height: DesignTokens.iconSizeS,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spaceS.left),
          Text(
            'Syncing...',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Empty state widget
class _EmptyNotesView extends StatelessWidget {
  final VoidCallback onCreateNote;
  final ThemeData theme;

  const _EmptyNotesView({required this.onCreateNote, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Container(
        padding: DesignTokens.pageMarginLarge,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Container(
              padding: DesignTokens.spaceXL,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXXL),
              ),
              child: Icon(
                Icons.note_add_outlined,
                size: DesignTokens.iconSizeXXL,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: DesignTokens.spaceL.top),

            // Empty state title
            Text(
              'Start your first note',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: DesignTokens.spaceS.top),

            // Empty state description
            Text(
              'Capture thoughts, ideas, and reminders securely',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: DesignTokens.spaceXL.top),

            // Create note button
            FilledButton.icon(
              onPressed: onCreateNote,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Note'),
            ),

            SizedBox(height: DesignTokens.spaceS.top),

            // Sync hint
            Text(
              'Pull down to sync with your other devices',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
