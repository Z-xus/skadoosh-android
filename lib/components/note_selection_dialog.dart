import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';
import 'package:home_widget/home_widget.dart';

/// Dialog to select a note for the home screen widget
class NoteSelectionDialog extends StatefulWidget {
  final String? widgetId;

  const NoteSelectionDialog({super.key, this.widgetId});

  @override
  State<NoteSelectionDialog> createState() => _NoteSelectionDialogState();
}

class _NoteSelectionDialogState extends State<NoteSelectionDialog> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final noteDb = Provider.of<NoteDatabase>(context, listen: false);
      final allNotes = await noteDb.getAllNotes();

      // Filter active notes only
      final activeNotes =
          allNotes.where((note) => !note.isDeleted && !note.isArchived).toList()
            ..sort(
              (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
                a.updatedAt ?? DateTime(1970),
              ),
            );

      setState(() {
        _notes = activeNotes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectNote(Note note) async {
    try {
      // Save selected note ID for this widget
      if (widget.widgetId != null) {
        await HomeWidget.saveWidgetData<String>(
          'note_widget_${widget.widgetId}_note_id',
          note.id.toString(),
        );
      }

      // Get note content
      final content = await note.getContent();
      final preview = content.length > 500
          ? '${content.substring(0, 500)}...'
          : content;

      // Update widget data
      await HomeWidget.saveWidgetData<String>('note_title', note.title);
      await HomeWidget.saveWidgetData<String>('note_content', preview);
      await HomeWidget.saveWidgetData<String>('note_id', note.id.toString());
      await HomeWidget.saveWidgetData<String>(
        'note_updated',
        note.updatedAt?.toIso8601String() ?? '',
      );

      // Update the widget
      await HomeWidget.updateWidget(
        name: 'NoteWidget',
        androidName: 'NoteWidgetProvider',
        iOSName: 'NoteWidget',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Widget updated with "${note.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error selecting note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update widget'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = themeProvider.currentTokens;

    return AlertDialog(
      backgroundColor: tokens.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      title: Row(
        children: [
          Icon(Icons.widgets_outlined, color: tokens.accentPrimary, size: 24),
          const SizedBox(width: 8),
          Text(
            'Select Note for Widget',
            style: TextStyle(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: tokens.accentPrimary),
              )
            : _notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 48,
                      color: tokens.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notes available',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a note first',
                      style: TextStyle(
                        color: tokens.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return _buildNoteListItem(note, tokens);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildNoteListItem(Note note, dynamic tokens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tokens.bgBase,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: tokens.borderSecondary, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.note, color: tokens.accentPrimary),
        title: Text(
          note.title,
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: note.updatedAt != null
            ? Text(
                _formatDate(note.updatedAt!),
                style: TextStyle(color: tokens.textTertiary, fontSize: 12),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: tokens.textTertiary),
        onTap: () => _selectNote(note),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
