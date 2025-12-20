import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/components/drawer.dart';
import 'package:skadoosh_app/components/note_tile.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/key_based_sync_service.dart';
// import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:skadoosh_app/pages/edit_note_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  KeyBasedSyncService? _syncService;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    readNotes();
    _initializeSyncService();
  }

  Future<void> _initializeSyncService() async {
    final noteDatabase = Provider.of<NoteDatabase>(context, listen: false);
    _syncService = KeyBasedSyncService(noteDatabase);
    await _syncService!.initialize();
  }

  void createNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditNotePage()),
    );
  }

  void readNotes() {
    context.read<NoteDatabase>().fetchNotes();
  }

  Future<void> _performSync() async {
    if (_syncService == null || _isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

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
        );
        // Refresh the notes list
        readNotes();
      } else {
        _showMessage('Sync failed: ${result.error}');
      }
    } catch (e) {
      _showMessage('Sync failed: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void updateNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditNotePage(note: note)),
    );
  }

  void moveNoteToTrash(int id) {
    context.read<NoteDatabase>().moveToTrash(id);
  }

  @override
  Widget build(BuildContext context) {
    final noteDatabase = context.watch<NoteDatabase>();
    List<Note> notes = noteDatabase.currentNotes;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Sync button in app bar
          IconButton(
            onPressed: _isSyncing ? null : _performSync,
            icon: _isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.sync,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
            tooltip: 'Sync notes',
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createNote();
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _performSync,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: Text(
                "Notes",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            // Sync status indicator
            if (_isSyncing)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Syncing...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            // List of notes
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.inversePrimary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notes yet',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .inversePrimary
                                  .withValues(alpha: 0.7),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pull down to sync or tap + to create a note',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .inversePrimary
                                  .withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when few items
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];

                        return NoteTile(
                          note: note,
                          onEditPressed: () => updateNote(note),
                          onDeletePressed: () => moveNoteToTrash(note.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
