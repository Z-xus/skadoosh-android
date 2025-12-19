import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';

class EditNotePage extends StatefulWidget {
  final Note? note;

  const EditNotePage({super.key, this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late EditorState _editorState;

  @override
  void initState() {
    super.initState();

    // Initialize the editor state from existing markdown or blank
    if (widget.note != null && widget.note!.title.isNotEmpty) {
      _editorState = EditorState(
        document: markdownToDocument(widget.note!.title),
      );
    } else {
      _editorState = EditorState.blank();
    }
  }

  @override
  void dispose() {
    _editorState.dispose();
    super.dispose();
  }

  void _saveNote() {
    final markdown = documentToMarkdown(_editorState.document);
    final noteDatabase = context.read<NoteDatabase>();

    if (widget.note == null) {
      // Create new note
      noteDatabase.addNote(markdown);
    } else {
      // Update existing note
      noteDatabase.updateNote(widget.note!.id, markdown);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.note == null ? 'New Note' : 'Edit Note',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _saveNote,
            icon: const Icon(Icons.save),
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: AppFlowyEditor(
        editorState: _editorState,
        characterShortcutEvents: standardCharacterShortcutEvents,
        commandShortcutEvents: standardCommandShortcutEvents,
        editorStyle: EditorStyle.mobile(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
          cursorColor: Theme.of(context).colorScheme.inversePrimary,
          selectionColor: Theme.of(context).colorScheme.inversePrimary,
          textStyleConfiguration: TextStyleConfiguration(
            text: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 16,
            ),
          ),
          dragHandleColor: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }
}
