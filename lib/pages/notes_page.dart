import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/components/drawer.dart';
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

  // 1. Add state for navigation
  int _currentIndex = 0;

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
    final noteDatabase = context.read<NoteDatabase>();
    noteDatabase.fetchNotes();
    noteDatabase.fetchHabits(); // Also initialize habits data
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
        // Adjusted margin to appear above the new bottom nav
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
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

  void _archiveNote(int id) {
    context.read<NoteDatabase>().archiveNote(id);
    _showMessage('Note archived', isSuccess: true);
  }

  // 2. Extracted the Notes View Logic to keep build method clean
  Widget _buildNotesView(ThemeData theme, ColorScheme colorScheme) {
    return FadeTransition(
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
                  // Increased bottom padding so the last note isn't hidden behind the floating bar
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final note = notes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _SwipeableNoteTile(
                          key: ValueKey(note.id),
                          note: note,
                          onTap: () => _updateNote(note),
                          onArchive: () => _archiveNote(note.id),
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
    );
  }

  // 3. Simple placeholders for the other pages
  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 4. Switch visible content
    Widget content;
    String title;

    switch (_currentIndex) {
      case 0:
        content = _buildNotesView(theme, colorScheme);
        title = 'Notes';
        break;
      case 1:
        content = _buildPlaceholderPage('Todos', Icons.check_circle_outline);
        title = 'Todos';
        break;
      case 2:
        content = _buildPlaceholderPage('Archive', Icons.inventory_2_outlined);
        title = 'Archive';
        break;
      case 3:
        content = _buildPlaceholderPage('Settings', Icons.settings_outlined);
        title = 'Settings';
        break;
      default:
        content = _buildNotesView(theme, colorScheme);
        title = 'Notes';
    }

    return Scaffold(
      // 5. CRITICAL: extendBody allows content to flow behind the navigation bar
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        title: Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          // Only show Sync button on Notes page
          if (_currentIndex == 0) ...[
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
        ],
      ),
      backgroundColor: colorScheme.surface,
      drawer: const MyDrawer(),
      // Hide FAB if not on Notes page
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _createNote,
              elevation: 2,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add_rounded),
            )
          : null,

      body: content,

      // 6. The Floating Custom Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 10),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
              _buildNavItem(1, Icons.task_alt_rounded, Icons.task_alt_outlined),
              _buildNavItem(
                2,
                Icons.inventory_2_rounded,
                Icons.inventory_2_outlined,
              ),
              _buildNavItem(3, Icons.settings_rounded, Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isSelected ? activeIcon : inactiveIcon,
            key: ValueKey<bool>(isSelected),
            color: isSelected ? Colors.white : Colors.grey.shade600,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// A swipeable note tile with dynamic containers for archive and delete actions
class _SwipeableNoteTile extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _SwipeableNoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  State<_SwipeableNoteTile> createState() => _SwipeableNoteTileState();
}

class _SwipeableNoteTileState extends State<_SwipeableNoteTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _dragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    // Starting drag
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dx;
      _dragDistance = _dragDistance.clamp(-150.0, 150.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Determine action based on drag distance
    if (_dragDistance > 80) {
      // Right swipe - archive
      _executeArchive();
    } else if (_dragDistance < -80) {
      // Left swipe - delete
      _executeDelete();
    } else {
      // Reset position
      _resetPosition();
    }
  }

  void _executeArchive() {
    _animationController.forward().then((_) {
      widget.onArchive();
      _resetPosition();
    });
  }

  void _executeDelete() {
    _animationController.forward().then((_) {
      widget.onDelete();
      _resetPosition();
    });
  }

  void _resetPosition() {
    setState(() {
      _dragDistance = 0.0;
    });
    _animationController.reverse();
  }

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
    final dateString = _formatDate(widget.note.updatedAt);

    // Calculate container dimensions based on drag distance
    double containerWidth = 0;
    IconData? actionIcon;
    Color? actionIconColor;
    Color? containerColor;
    bool showLeftContainer = false;
    bool showRightContainer = false;

    if (_dragDistance > 15) {
      // Right swipe - archive
      containerWidth = _dragDistance.abs().clamp(0.0, 120.0);
      containerColor = Colors.amber.shade200;
      actionIcon = Icons.archive_rounded;
      actionIconColor = Colors.amber.shade800;
      showLeftContainer = true;
    } else if (_dragDistance < -15) {
      // Left swipe - delete
      containerWidth = _dragDistance.abs().clamp(0.0, 120.0);
      containerColor = Colors.red.shade200;
      actionIcon = Icons.delete_rounded;
      actionIconColor = Colors.red.shade800;
      showRightContainer = true;
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        height: 80, // Fixed height for consistent container sizing
        child: Stack(
          children: [
            // Left container (archive - yellow)
            if (showLeftContainer)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: containerWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Icon(
                        actionIcon!,
                        color: actionIconColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Right container (delete - red)
            if (showRightContainer)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: containerWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(
                        actionIcon!,
                        color: actionIconColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Main note tile that moves
            Transform.translate(
              offset: Offset(_dragDistance * 0.5, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
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
                        if (widget.note.title.isNotEmpty) ...[
                          Text(
                            widget.note.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
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
                            Icon(
                              widget.note.needsSync
                                  ? Icons.cloud_upload_rounded
                                  : Icons.cloud_done_rounded,
                              size: 14,
                              color: widget.note.needsSync
                                  ? Colors.orange.shade600
                                  : Colors.green.shade600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
