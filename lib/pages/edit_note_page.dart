import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/storage_service.dart';
import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EditNotePage extends StatefulWidget {
  final Note? note;
  final String? folderPath; // NEW: For creating notes in specific folders

  const EditNotePage({super.key, this.note, this.folderPath});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late EditorState _editorState;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPreviewMode = false;
  bool _hasBeenSaved = false;

  @override
  void initState() {
    super.initState();
    // Initialize saved state
    _hasBeenSaved = widget.note != null;
    // Initialize with a blank editor state to prevent LateInitializationError
    _editorState = EditorState.blank();
    _addSelectionListener();
    _loadNoteContent();
  }

  Future<void> _loadNoteContent() async {
    try {
      // 1. New Note
      if (widget.note == null) {
        final newState = EditorState(
          document: Document(
            root: pageNode(children: [headingNode(level: 1), paragraphNode()]),
          ),
        );
        if (mounted) {
          setState(() {
            _removeSelectionListener(); // Remove from old state
            _editorState.dispose(); // Dispose old state
            _editorState = newState;
            _addSelectionListener(); // Add to new state
          });
        }
        return;
      }

      // 2. Existing Note
      String content = '';
      if (widget.note!.relativePath != null) {
        content = await StorageService().readNote(widget.note!.relativePath!);
      } else if (widget.note!.fileName != null) {
        content = await StorageService().readNote(widget.note!.fileName!);
      } else if (widget.note!.body.isNotEmpty) {
        content = widget.note!.body;
      }

      if (content.isNotEmpty) {
        final newState = EditorState(document: markdownToDocument(content));
        if (mounted) {
          setState(() {
            _removeSelectionListener(); // Remove from old state
            _editorState.dispose(); // Dispose old state
            _editorState = newState;
            _addSelectionListener(); // Add to new state
          });
        }
      } else {
        final newState = EditorState.blank();
        if (mounted) {
          setState(() {
            _removeSelectionListener(); // Remove from old state
            _editorState.dispose(); // Dispose old state
            _editorState = newState;
            _addSelectionListener(); // Add to new state
          });
        }
      }
    } catch (e) {
      // If loading fails, keep the blank state
      print('Error loading note content: $e');
    }
  }

  @override
  void dispose() {
    _removeSelectionListener();
    _editorState.dispose();
    super.dispose();
  }

  // --- Selection Change Listener for Real-time Button Updates ---
  void _addSelectionListener() {
    _editorState.selectionNotifier.addListener(_onSelectionChanged);
  }

  void _removeSelectionListener() {
    _editorState.selectionNotifier.removeListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    // Update UI to reflect current formatting state at cursor position
    if (mounted) {
      setState(() {
        // Debug: Log selection changes
        print('🎯 Selection changed - updating button states');
      });
    }
  }

  void _saveNote() async {
    final noteDatabase = context.read<NoteDatabase>();
    final storageService = StorageService();

    final nodes = _editorState.document.root.children;
    String extractedTitle = 'Untitled';
    if (nodes.isNotEmpty) {
      final firstNodeText = nodes.first.delta?.toPlainText().trim() ?? '';
      extractedTitle = firstNodeText.split('\n').first;
    }
    if (extractedTitle.isEmpty) extractedTitle = 'Untitled';

    final body = documentToMarkdown(_editorState.document);

    if (extractedTitle == 'Untitled' && body.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    String fileName =
        widget.note?.fileName ??
        storageService.sanitizeFilename(extractedTitle);

    // Handle folder path for file storage
    final folderPath = widget.note?.folderPath ?? widget.folderPath ?? '';
    final fullPath = folderPath.isEmpty ? fileName : '$folderPath/$fileName';

    await storageService.writeNote(fullPath, body);

    if (!_hasBeenSaved && widget.note == null) {
      // Creating a new note - only do this once
      if (widget.folderPath != null && widget.folderPath!.isNotEmpty) {
        // Creating note in a specific folder
        await noteDatabase.addNoteToFolder(
          extractedTitle,
          widget.folderPath!,
          body: body,
          fileName: fileName,
        );
      } else {
        // Creating note in root folder
        await noteDatabase.addNote(
          extractedTitle,
          body: body,
          fileName: fileName,
          relativePath: fileName,
        );
      }
      // Mark as saved to prevent duplicates
      _hasBeenSaved = true;
    } else if (widget.note != null) {
      // Updating existing note
      await noteDatabase.updateNote(
        widget.note!.id,
        extractedTitle,
        body: body,
        fileName: fileName,
        relativePath: fullPath,
      );
    }

    // Switch to preview mode after save
    setState(() {
      _isPreviewMode = true;
    });

    // Show save feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // --- Modern Floating Toolbar Configuration ---
  Widget _buildModernFloatingToolbar() {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = themeProvider.currentTokens;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tokens.bgBase.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolbarButton(
              icon: Icons.format_bold_rounded,
              isSelected: _isFormatActive('bold'),
              onTap: () => _toggleFormat('bold'),
            ),
            _buildToolbarButton(
              icon: Icons.format_italic_rounded,
              isSelected: _isFormatActive('italic'),
              onTap: () => _toggleFormat('italic'),
            ),
            _buildToolbarButton(
              icon: Icons.format_underlined_rounded,
              isSelected: _isFormatActive('underline'),
              onTap: () => _toggleFormat('underline'),
            ),
            _buildToolbarButton(
              icon: Icons.title_rounded,
              isSelected: _isFormatActive('heading'),
              onTap: () => _toggleHeading(),
            ),
            _buildToolbarButton(
              icon: Icons.format_list_bulleted_rounded,
              isSelected: _isFormatActive('bulleted_list'),
              onTap: () => _toggleBulletList(),
            ),
            _buildToolbarButton(
              icon: Icons.image,
              isSelected: false,
              onTap: _showImagePicker,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarButton(
                  icon: Icons.undo_rounded,
                  isSelected: false,
                  onTap: () => _editorState.undoManager.undo(),
                ),
                const SizedBox(width: 4),
                _buildToolbarButton(
                  icon: Icons.redo_rounded,
                  isSelected: false,
                  onTap: () => _editorState.undoManager.redo(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = themeProvider.currentTokens;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.accentPrimary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? tokens.accentPrimary : tokens.textSecondary,
        ),
      ),
    );
  }

  // Helper methods for formatting - FIXED to use proper AppFlowy API
  bool _isFormatActive(String format) {
    try {
      final selection = _editorState.selection;
      if (selection == null) return false;

      print(
        'Checking format: $format for selection: ${selection.start.path}',
      ); // Debug logging

      switch (format) {
        case 'bold':
        case 'italic':
        case 'underline':
          // Use the correct AppFlowy v6.2.0 API instead of manual delta parsing
          final value = _editorState.getDeltaAttributeValueInSelection<bool>(
            format,
          );
          print('Format $format value: $value'); // Debug logging
          return value == true;
        case 'heading':
          final node = _editorState.getNodeAtPath(selection.start.path);
          final isHeading = node?.type == 'heading';
          print(
            'Is heading: $isHeading, node type: ${node?.type}',
          ); // Debug logging
          return isHeading;
        case 'bulleted_list':
          final node = _editorState.getNodeAtPath(selection.start.path);
          final isBulletList = node?.type == 'bulleted_list';
          print(
            'Is bullet list: $isBulletList, node type: ${node?.type}',
          ); // Debug logging
          return isBulletList;
        default:
          return false;
      }
    } catch (e) {
      print('Error checking format $format: $e');
      return false;
    }
  }

  void _toggleFormat(String format) {
    try {
      print('Toggling format: $format'); // Debug logging
      _editorState.toggleAttribute(format);
      // Force UI update to refresh button states
      setState(() {});
      print('Format toggled successfully: $format'); // Debug logging
    } catch (e) {
      print('Error toggling format $format: $e');
    }
  }

  void _toggleHeading() {
    try {
      print('Toggling heading'); // Debug logging
      final selection = _editorState.selection;
      if (selection == null) return;

      final node = _editorState.getNodeAtPath(selection.start.path);
      if (node == null) return;

      if (node.type == 'heading') {
        print('Converting heading to paragraph'); // Debug logging
        // Convert heading to paragraph
        _editorState.formatNode(
          selection,
          (node) => node.copyWith(
            type: 'paragraph',
            attributes: Map<String, dynamic>.from(node.attributes)
              ..remove('level'),
          ),
        );
      } else {
        print('Converting paragraph to heading'); // Debug logging
        // Convert to heading
        _editorState.formatNode(
          selection,
          (node) => node.copyWith(
            type: 'heading',
            attributes: Map<String, dynamic>.from(node.attributes)
              ..['level'] = 1,
          ),
        );
      }
      // Force UI update to refresh button states
      setState(() {});
      print('Heading toggle completed'); // Debug logging
    } catch (e) {
      print('Error toggling heading: $e');
    }
  }

  void _toggleBulletList() {
    try {
      print('Toggling bullet list'); // Debug logging
      final selection = _editorState.selection;
      if (selection == null) return;

      final node = _editorState.getNodeAtPath(selection.start.path);
      if (node == null) return;

      if (node.type == 'bulleted_list') {
        print('Converting bullet list to paragraph'); // Debug logging
        // Convert to paragraph
        _editorState.formatNode(
          selection,
          (node) => node.copyWith(type: 'paragraph'),
        );
      } else {
        print('Converting paragraph to bullet list'); // Debug logging
        // Convert to bulleted list
        _editorState.formatNode(
          selection,
          (node) => node.copyWith(type: 'bulleted_list'),
        );
      }
      // Force UI update to refresh button states
      setState(() {});
      print('Bullet list toggle completed'); // Debug logging
    } catch (e) {
      print('Error toggling bullet list: $e');
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
    });
  }

  void _showImagePicker() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _insertImageAsWidget(pickedFile);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  Future<void> _insertImageAsWidget(XFile imageFile) async {
    try {
      final selection = _editorState.selection;
      if (selection == null || !selection.isCollapsed) return;

      // Create images directory if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'image_$timestamp$extension';
      final filePath = '${imagesDir.path}/$fileName';

      // Copy the image to our images directory
      final imageBytes = await imageFile.readAsBytes();
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Get the node and path for insertion
      final node = _editorState.getNodeAtPath(selection.end.path);
      if (node == null) return;

      final transaction = _editorState.transaction;

      // Create image node with proper URL
      final imageNode = Node(
        type: 'image',
        attributes: {
          'url': file.path,
          'align': 'center',
          'width': 300.0,
          'height': 200.0,
        },
      );

      // If current node is empty paragraph, replace it
      if (node.type == 'paragraph' && (node.delta?.isEmpty ?? false)) {
        transaction
          ..insertNode(node.path, imageNode)
          ..deleteNode(node);
      } else {
        // Insert after current node
        transaction.insertNode(node.path.next, imageNode);
      }

      // Set cursor after the image
      transaction.afterSelection = Selection.collapsed(
        Position(path: node.path.next, offset: 0),
      );

      await _editorState.apply(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image added to note'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error inserting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inserting image: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = themeProvider.currentTokens;
    final textColor = tokens.textPrimary;
    final bgColor = tokens.bgBase;

    // Get keyboard height for proper positioning
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (!mounted) return const Scaffold();

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom:
                false, // Don't add bottom safe area - we'll handle it manually
            child: Column(
              children: [
                // --- Header ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.borderSecondary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Icon(Icons.close, size: 20, color: textColor),
                        ),
                      ),
                      Text(
                        _isPreviewMode
                            ? 'Preview Mode'
                            : (widget.note == null ? 'New Note' : 'Edit Note'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        onPressed: _isPreviewMode ? _toggleEditMode : _saveNote,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.borderSecondary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Icon(
                            _isPreviewMode ? Icons.edit : Icons.save,
                            size: 20,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Editor Area ---
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: _isPreviewMode
                          ? 16
                          : 80, // No toolbar in preview mode
                    ),
                    child: AppFlowyEditor(
                      editorState: _editorState,
                      editable:
                          !_isPreviewMode, // Disable editing in preview mode
                      editorStyle: EditorStyle.mobile(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, // Reduced padding
                          vertical: 8,
                        ),
                        cursorColor: _isPreviewMode
                            ? Colors.transparent
                            : tokens.accentPrimary,
                        selectionColor: _isPreviewMode
                            ? Colors.transparent
                            : tokens.accentPrimary.withValues(alpha: 0.2),
                        dragHandleColor: _isPreviewMode
                            ? Colors.transparent
                            : tokens.accentPrimary,
                        textStyleConfiguration: TextStyleConfiguration(
                          text: TextStyle(
                            fontSize: 17,
                            color: textColor,
                            height: 1.5,
                          ),
                          // Add explicit text formatting styles for visual feedback
                          bold: const TextStyle(fontWeight: FontWeight.bold),
                          italic: const TextStyle(fontStyle: FontStyle.italic),
                          underline: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Modern Floating Toolbar (only in edit mode) ---
          if (!_isPreviewMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboardHeight > 0 ? keyboardHeight + 16 : 16,
              child: _buildModernFloatingToolbar(),
            ),
        ],
      ),
    );
  }
}
