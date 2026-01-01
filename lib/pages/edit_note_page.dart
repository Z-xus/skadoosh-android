import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/storage_service.dart';
import 'package:skadoosh_app/services/image_service.dart';
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
      // Fix selection issue - get or create valid selection
      Selection? selection = _editorState.selection;
      if (selection == null || !selection.isCollapsed) {
        // Create selection at end of document
        final document = _editorState.document;
        final lastNode = document.root.children.lastOrNull;
        if (lastNode != null) {
          selection = Selection.collapsed(
            Position(path: lastNode.path, offset: lastNode.delta?.length ?? 0),
          );
        } else {
          // Document is empty, create first paragraph
          final transaction = _editorState.transaction;
          transaction.insertNode([0], paragraphNode());
          await _editorState.apply(transaction);
          selection = Selection.collapsed(Position(path: [0], offset: 0));
        }
      }

      String imageUrl;

      // ALWAYS save locally first (consistent with note creation flow)
      print('📱 Saving image locally...');
      final localImagePath = await _saveImageLocally(imageFile);
      imageUrl = localImagePath; // Default to local path

      // If note is synced, ALSO upload to R2 for immediate display
      String? r2ImageUrl;
      if (widget.note != null &&
          widget.note!.serverId != null &&
          widget.note!.serverId!.isNotEmpty) {
        try {
          print(
            '🔄 Note is synced, also uploading to R2 for immediate display...',
          );
          final imageService = ImageService();
          await imageService.initialize();

          final imageFileObj = File(imageFile.path);
          final result = await imageService.uploadImage(
            imageFile: imageFileObj,
            noteId: widget.note!.serverId!,
          );

          if (result.success && result.publicUrl != null) {
            r2ImageUrl = result.publicUrl!;
            imageUrl = r2ImageUrl; // Use R2 URL for display
            print('✅ R2 upload successful: $r2ImageUrl');
          }
        } catch (e) {
          print('❌ R2 upload failed, will use local path: $e');
          // Continue with local path
        }
      }

      // Track local and R2 paths for sync process
      if (widget.note != null) {
        final currentNote = widget.note!;
        final currentLocalPaths = List<String>.from(
          currentNote.localImagePaths,
        );
        final currentR2Urls = List<String>.from(currentNote.imageUrls);

        // Always add to local paths
        currentLocalPaths.add(localImagePath);

        // Add to R2 URLs if uploaded successfully
        if (r2ImageUrl != null) {
          currentR2Urls.add(r2ImageUrl);
        }

        // Create updated note
        final updatedNote = Note()
          ..id = currentNote.id
          ..title = currentNote.title
          ..body = currentNote.body
          ..fileName = currentNote.fileName
          ..relativePath = currentNote.relativePath
          ..folderPath = currentNote.folderPath
          ..shadowContentZLib = currentNote.shadowContentZLib
          ..lastSyncedHash = currentNote.lastSyncedHash
          ..isDirty =
              true // Mark as dirty since we added an image
          ..isDeleted = currentNote.isDeleted
          ..deletedAt = currentNote.deletedAt
          ..isArchived = currentNote.isArchived
          ..archivedAt = currentNote.archivedAt
          ..serverId = currentNote.serverId
          ..createdAt = currentNote.createdAt
          ..updatedAt = DateTime.now()
          ..lastSyncedAt = currentNote.lastSyncedAt
          ..needsSync =
              true // Mark for sync since content changed
          ..deviceId = currentNote.deviceId
          ..imageUrls = currentR2Urls
          ..localImagePaths = currentLocalPaths
          ..hasImages = true;

        await NoteDatabase.isar.writeTxn(() async {
          await NoteDatabase.isar.notes.put(updatedNote);
        });
        print('✅ Local image path saved to database');
      }

      // Continue with the rest of the logic...

      // Insert image as proper markdown text instead of custom node
      // This ensures proper newlines and markdown formatting
      final node = _editorState.getNodeAtPath(selection.end.path);
      if (node == null) return;

      final transaction = _editorState.transaction;

      // Create markdown image syntax with proper newlines
      final imageMarkdown = '![]($imageUrl)';

      // Create three new paragraph nodes:
      // 1. Empty line before image
      // 2. Image paragraph
      // 3. Empty line after image
      final emptyBefore = paragraphNode();
      final imageParagraph = paragraphNode(text: imageMarkdown);
      final emptyAfter = paragraphNode();

      // If current node is empty paragraph, insert image here
      if (node.type == 'paragraph' && (node.delta?.isEmpty ?? true)) {
        final insertPath = node.path;
        transaction
          ..insertNode(insertPath, imageParagraph)
          ..insertNode(insertPath.next, emptyAfter)
          ..deleteNode(node); // Remove the empty node we replaced
      } else {
        // Insert after current node with proper spacing
        final nextPath = node.path.next;
        transaction
          ..insertNode(nextPath, emptyBefore)
          ..insertNode(nextPath.next, imageParagraph)
          ..insertNode(nextPath.next.next, emptyAfter);
      }

      // Set cursor to the empty line after image
      final cursorPath =
          node.type == 'paragraph' && (node.delta?.isEmpty ?? true)
          ? node.path.next
          : node.path.next.next.next;

      transaction.afterSelection = Selection.collapsed(
        Position(path: cursorPath, offset: 0),
      );

      await _editorState.apply(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageUrl.startsWith('http')
                  ? 'Image uploaded to cloud and added to note'
                  : 'Image added to note (will sync when note syncs)',
            ),
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

  Future<String> _saveImageLocally(XFile imageFile) async {
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

    return file.path;
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
                    child: MobileFloatingToolbar(
                      editorState: _editorState,
                      editorScrollController: EditorScrollController(
                        editorState: _editorState,
                        shrinkWrap: false,
                      ),
                      floatingToolbarHeight: 32,
                      toolbarBuilder: (context, anchor, closeToolbar) {
                        return AdaptiveTextSelectionToolbar.editable(
                          clipboardStatus: ClipboardStatus.pasteable,
                          onCopy: () {
                            copyCommand.execute(_editorState);
                            closeToolbar();
                          },
                          onCut: () {
                            cutCommand.execute(_editorState);
                            closeToolbar();
                          },
                          onPaste: () {
                            pasteCommand.execute(_editorState);
                            closeToolbar();
                          },
                          onSelectAll: () {
                            selectAllCommand.execute(_editorState);
                            closeToolbar();
                          },
                          onLiveTextInput: null,
                          onLookUp: null,
                          onSearchWeb: null,
                          onShare: null,
                          anchors: TextSelectionToolbarAnchors(
                            primaryAnchor: anchor,
                          ),
                        );
                      },
                      child: AppFlowyEditor(
                        editorState: _editorState,
                        editable:
                            !_isPreviewMode, // Disable editing in preview mode
                        showMagnifier:
                            true, // Enable magnifier and text selection toolbar on mobile
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
                            italic: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                            underline: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
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
