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
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();

    // Initialize title controller
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    // Initialize the editor state from existing body or blank
    if (widget.note != null && widget.note!.body.isNotEmpty) {
      _editorState = EditorState(
        document: markdownToDocument(widget.note!.body),
      );
    } else {
      _editorState = EditorState.blank();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final body = documentToMarkdown(_editorState.document);
    final noteDatabase = context.read<NoteDatabase>();

    if (title.isEmpty && body.trim().isEmpty) {
      // Don't save empty notes
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      // Create new note
      noteDatabase.addNote(title.isEmpty ? 'Untitled' : title, body: body);
    } else {
      // Update existing note
      noteDatabase.updateNote(
        widget.note!.id,
        title.isEmpty ? 'Untitled' : title,
        body: body,
      );
    }

    Navigator.pop(context);
  }

  final List<CharacterShortcutEvent> customCharacterShortcuts = [
    ...standardCharacterShortcutEvents,
    ...markdownSyntaxShortcutEvents,
  ];

  @override
  Widget build(BuildContext context) {
    // Use system default font instead of Google Fonts
    final baseStyle = TextStyle(
      color: Theme.of(context).colorScheme.inversePrimary,
      fontSize: 16,
    );

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
      body: Column(
        children: [
          // Title field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
            child: TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Note title...',
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.inversePrimary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Divider(
              color: Theme.of(
                context,
              ).colorScheme.inversePrimary.withValues(alpha: 0.3),
            ),
          ),

          // Body editor
          Expanded(
            child: AppFlowyEditor(
              editorState: _editorState,
              characterShortcutEvents: customCharacterShortcuts,
              editorStyle: EditorStyle.mobile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 0,
                ),
                cursorColor: Theme.of(context).colorScheme.inversePrimary,
                selectionColor: Theme.of(context).colorScheme.inversePrimary,
                textStyleConfiguration: TextStyleConfiguration(
                  text: baseStyle,
                  bold: baseStyle.copyWith(fontWeight: FontWeight.bold),
                  italic: baseStyle.copyWith(fontStyle: FontStyle.italic),
                ),
                dragHandleColor: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
