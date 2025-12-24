import 'package:skadoosh_app/models/note.dart';
import 'dart:io';

/// Service for managing simple single-level folder structure
class FolderService {
  /// Validates a folder name (single level only - no slashes)
  static bool isValidFolderName(String name) {
    if (name.isEmpty) return true; // Root is valid
    if (name.length > 30) return false; // Reasonable limit for chips UI

    // No slashes allowed (single level only)
    if (name.contains('/')) return false;

    // Check for invalid characters (platform-specific)
    final invalidChars = Platform.isWindows
        ? RegExp(r'[<>:"/\\|?*]')
        : RegExp(r'[/\0]');

    return !invalidChars.hasMatch(name) && name.trim() == name;
  }

  /// Normalizes a folder name (trims whitespace)
  static String normalizeFolderName(String name) {
    return name.trim();
  }

  /// Creates a full file path from folder name and filename
  static String createFullPath(String folderName, String fileName) {
    final normalizedFolder = normalizeFolderName(folderName);
    if (normalizedFolder.isEmpty) return fileName;
    return '$normalizedFolder/$fileName';
  }

  /// Extracts folder name from a full file path (single level only)
  static String extractFolderName(String fullPath) {
    if (!fullPath.contains('/')) return ''; // No folder, it's in root
    final parts = fullPath.split('/');
    return parts.length > 1 ? parts.first : '';
  }

  /// Extracts filename from a full file path
  static String extractFileName(String fullPath) {
    final lastSlashIndex = fullPath.lastIndexOf('/');
    if (lastSlashIndex == -1) {
      return fullPath; // No folder, entire path is filename
    }
    return fullPath.substring(lastSlashIndex + 1);
  }
}

/// Simple data class representing a folder
class FolderInfo {
  final String name;
  final int noteCount;

  const FolderInfo({required this.name, required this.noteCount});

  bool get isRoot => name.isEmpty;
  String get displayName => isRoot ? 'All' : name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FolderInfo && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Helper class to organize notes by folder (simplified for chip-based filtering)
class FolderStructure {
  final Map<String, List<Note>> _folderNotes = {};
  final List<Note> _allNotes;

  FolderStructure(this._allNotes) {
    _buildStructure();
  }

  void _buildStructure() {
    _folderNotes.clear();

    // Group notes by folder
    for (final note in _allNotes) {
      final folderName = note.folderPath ?? '';
      _folderNotes.putIfAbsent(folderName, () => []).add(note);
    }
  }

  /// Gets all folders with note counts
  List<FolderInfo> getAllFolders() {
    final folders = <FolderInfo>[];

    // Add "All" folder first
    folders.add(FolderInfo(name: '', noteCount: _allNotes.length));

    // Add other folders, sorted alphabetically
    final folderNames =
        _folderNotes.keys.where((name) => name.isNotEmpty).toList()..sort();

    for (final name in folderNames) {
      folders.add(
        FolderInfo(name: name, noteCount: _folderNotes[name]?.length ?? 0),
      );
    }

    return folders;
  }

  /// Gets notes in a specific folder (empty string = all notes)
  List<Note> getNotesInFolder(String folderName) {
    if (folderName.isEmpty) return _allNotes; // "All" folder
    return _folderNotes[folderName] ?? [];
  }

  /// Gets all unique folder names that contain notes
  List<String> getFolderNames() {
    return _folderNotes.keys
        .where((name) => name.isNotEmpty && _folderNotes[name]!.isNotEmpty)
        .toList()
      ..sort();
  }

  /// Checks if a folder exists and has notes
  bool folderHasNotes(String folderName) {
    if (folderName.isEmpty) return _allNotes.isNotEmpty;
    return _folderNotes[folderName]?.isNotEmpty ?? false;
  }
}
