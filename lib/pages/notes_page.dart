import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/components/drawer.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/key_based_sync_service.dart';
import 'package:skadoosh_app/services/folder_service.dart';
import 'package:skadoosh_app/pages/edit_note_page.dart';
import 'package:skadoosh_app/pages/rituals_page.dart';
import 'package:skadoosh_app/pages/settings.dart';
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

  // 1. Current page is always Notes (0) since navigation goes to other pages
  int _currentIndex = 0;

  // NEW: Folder filtering state
  String _selectedFolder = ''; // Empty = "All", folder name = specific folder

  // NEW: Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Note> _searchResults = [];

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
    _searchController.dispose();
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

  // NEW: Search functionality
  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final noteDatabase = context.read<NoteDatabase>();
    final results = await noteDatabase.searchNotes(query);

    setState(() {
      _searchResults = results;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _searchResults = [];
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _searchResults = [];
    });
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
          "Sync completed! Pushed: ${result.pushedNotes}, Pulled: ${result.pulledNotes}",
          isSuccess: true,
        );
        _readNotes();
      } else {
        _showMessage("Sync failed: ${result.error}", isError: true);
      }
    } catch (e) {
      _showMessage("Sync failed: $e", isError: true);
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

  // 2. Updated Notes View Logic with chip-based folder filtering
  Widget _buildNotesView(ThemeData theme, ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _performSync,
        color: colorScheme.primary,
        child: Consumer<NoteDatabase>(
          builder: (context, noteDatabase, child) {
            // If searching, use search results instead of filtering by folder
            final notes = _isSearching && _searchQuery.isNotEmpty
                ? _searchResults
                : noteDatabase.currentNotes;

            if (notes.isEmpty && !_isSearching) {
              return _EmptyNotesView(onCreateNote: _createNote, theme: theme);
            }

            // Build folder structure for filtering (only when not searching)
            List<Note> displayNotes;
            if (_isSearching && _searchQuery.isNotEmpty) {
              displayNotes = _searchResults;
            } else {
              final folderStructure = FolderStructure(notes);
              displayNotes = folderStructure.getNotesInFolder(_selectedFolder);
            }

            return Column(
              children: [
                // Only show folder chips when not searching
                if (!_isSearching || _searchQuery.isEmpty)
                  _FolderChipsBar(
                    folders: FolderStructure(notes).getAllFolders(),
                    selectedFolder: _selectedFolder,
                    onFolderSelected: _onFolderSelected,
                    onCreateFolder: _showCreateFolderDialog,
                    colorScheme: colorScheme,
                  ),
                // Notes list
                Expanded(
                  child: displayNotes.isEmpty
                      ? _isSearching && _searchQuery.isNotEmpty
                            ? _EmptySearchView(
                                query: _searchQuery,
                                theme: theme,
                              )
                            : _EmptyFolderView(
                                folderName: _selectedFolder.isEmpty
                                    ? 'All'
                                    : _selectedFolder,
                                onCreateNote: () =>
                                    _createNoteInCurrentFolder(),
                                theme: theme,
                              )
                      : CustomScrollView(
                          slivers: [
                            // Show search info banner if searching
                            if (_isSearching && _searchQuery.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.search_rounded,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Found ${displayNotes.length} result${displayNotes.length == 1 ? '' : 's'} for "$_searchQuery"',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.onSurface,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                100,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final note = displayNotes[index];
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
                                }, childCount: displayNotes.length),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onFolderSelected(String folderName) {
    setState(() {
      _selectedFolder = folderName;
    });
  }

  void _createNoteInCurrentFolder() {
    if (_selectedFolder.isEmpty) {
      _createNote(); // Root folder
    } else {
      _createNoteInFolder(_selectedFolder); // Specific folder
    }
  }

  void _createNoteInFolder(String folderName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) =>
            EditNotePage(folderPath: folderName),
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

  void _showCreateFolderDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'e.g., Work, Personal, Ideas',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Single-level folders only',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final folderName = controller.text.trim();
              if (folderName.isNotEmpty &&
                  FolderService.isValidFolderName(folderName)) {
                Navigator.of(context).pop();
                _createNoteInFolder(folderName);
              } else {
                _showMessage('Invalid folder name', isError: true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 4. Show Notes view since this page is specifically for Notes
    Widget content = _buildNotesView(theme, colorScheme);
    String title = 'Notes';

    return Scaffold(
      // 5. CRITICAL: extendBody allows content to flow behind the navigation bar
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        title: _isSearching
            ? _buildSearchBar(colorScheme)
            : Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
        centerTitle: false,
        leading: _isSearching
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.onSurface,
                ),
                onPressed: _toggleSearch,
              )
            : null,
        actions: [
          // Search button
          if (_currentIndex == 0 && !_isSearching)
            IconButton(
              onPressed: _toggleSearch,
              icon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
              tooltip: 'Search notes',
            ),
          // Only show Sync button on Notes page
          if (_currentIndex == 0 && !_isSearching) ...[
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
              onPressed: _createNoteInCurrentFolder,
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
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.2),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                0,
                Icons.note_rounded,
                Icons.note_outlined,
                "Notes",
              ),
              _buildNavItem(
                1,
                Icons.auto_awesome_rounded,
                Icons.auto_awesome_outlined,
                "Rituals",
              ),
              _buildNavItem(
                2,
                Icons.settings_rounded,
                Icons.settings_outlined,
                "Settings",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (index == _currentIndex) return; // Don't navigate to same page

        switch (index) {
          case 0:
            // Stay on Notes page - do nothing
            setState(() => _currentIndex = 0);
            break;
          case 1:
            // Navigate to Rituals page
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => const RitualsPage(),
                transitionDuration: DesignTokens.animationMedium,
                transitionsBuilder: (context, animation, _, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
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
            break;
          case 2:
            // Navigate to Settings page
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, _) => const SettingsPage(),
                transitionDuration: DesignTokens.animationMedium,
                transitionsBuilder: (context, animation, _, child) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
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
            break;
        }
      },
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
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 26,
          ),
        ),
      ),
    );
  }

  // NEW: Build search AppBar title
  Widget _buildSearchBar(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search notes...',
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: InputBorder.none,
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                onPressed: _clearSearch,
              )
            : null,
      ),
      onChanged: (value) => _performSearch(value),
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
    if (diff.inDays < 7) return "${diff.inDays} days ago";

    return "${date.day}/${date.month}/${date.year}";
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
                          const SizedBox(height: 4),
                        ],

                        // Tags (show first 3 only)
                        if (widget.note.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: widget.note.tags.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),
                        ],

                        const Spacer(),

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

/// Horizontal scrollable folder chips bar
class _FolderChipsBar extends StatelessWidget {
  final List<FolderInfo> folders;
  final String selectedFolder;
  final Function(String) onFolderSelected;
  final VoidCallback onCreateFolder;
  final ColorScheme colorScheme;

  const _FolderChipsBar({
    required this.folders,
    required this.selectedFolder,
    required this.onFolderSelected,
    required this.onCreateFolder,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Scrollable folder list
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: folders.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // Regular folder chips
                final folder = folders[index];
                final isSelected = selectedFolder == folder.name;

                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(folder.displayName),
                      if (folder.noteCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.2)
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.2,
                                  ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${folder.noteCount}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  showCheckmark: false, // Remove the tick icon
                  onSelected: (_) => onFolderSelected(folder.name),
                  backgroundColor: colorScheme.surface,
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          ),
          // Fixed create folder button on the right
          Container(
            width: 48, // Fixed width to prevent overflow
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: onCreateFolder,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.create_new_folder_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
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

/// Empty state for when a folder has no notes
class _EmptyFolderView extends StatelessWidget {
  final String folderName;
  final VoidCallback onCreateNote;
  final ThemeData theme;

  const _EmptyFolderView({
    required this.folderName,
    required this.onCreateNote,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final isAllFolder = folderName == 'All';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAllFolder ? Icons.edit_note_rounded : Icons.folder_outlined,
            size: 64,
            color: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            isAllFolder ? "No notes yet" : "No notes in $folderName",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAllFolder
                ? 'Create your first note'
                : 'Add a note to this folder',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onCreateNote,
            icon: const Icon(Icons.add, size: 18),
            label: Text(isAllFolder ? 'Create Note' : 'Add Note'),
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

/// Empty state for when search returns no results
class _EmptySearchView extends StatelessWidget {
  final String query;
  final ThemeData theme;

  const _EmptySearchView({required this.query, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'No notes found matching "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
