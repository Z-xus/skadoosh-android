import 'package:flutter/material.dart';

/// Enumeration of available theme families
enum ThemeFamily {
  catppuccin('Catppuccin', 'catppuccin'),
  nord('Nord', 'nord'),
  dracula('Dracula', 'dracula');

  const ThemeFamily(this.displayName, this.id);

  /// Human-readable name for the theme family
  final String displayName;

  /// Internal identifier used for storage and lookup
  final String id;
}

/// Represents a specific theme variant within a theme family
class ThemeVariant {
  const ThemeVariant({
    required this.id,
    required this.displayName,
    required this.brightness,
    this.description,
  });

  /// Internal identifier for the variant
  final String id;

  /// Human-readable name
  final String displayName;

  /// Whether this is a light or dark variant
  final Brightness brightness;

  /// Optional description of the variant
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeVariant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ThemeVariant(id: $id, displayName: $displayName)';
}

/// Complete theme configuration combining family and variant
class ThemeConfig {
  const ThemeConfig({required this.family, required this.variant});

  /// The theme family
  final ThemeFamily family;

  /// The specific variant within the family
  final ThemeVariant variant;

  /// Get a unique identifier for this theme configuration
  String get id => '${family.id}_${variant.id}';

  /// Get display name for this configuration
  String get displayName => '${family.displayName} ${variant.displayName}';

  /// Get brightness of this configuration
  Brightness get brightness => variant.brightness;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeConfig &&
          runtimeType == other.runtimeType &&
          family == other.family &&
          variant == other.variant;

  @override
  int get hashCode => Object.hash(family, variant);

  @override
  String toString() => 'ThemeConfig(${family.id}, ${variant.id})';
}
