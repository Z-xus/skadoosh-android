import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skadoosh_app/models/note.dart';

class CustomImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? alignment;
  final Note? note; // NEW: Optional note for accessing image path map

  const CustomImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment,
    this.note, // NEW: Pass note for offline fallback
  });

  bool get isNetworkUrl =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  bool get isLocalFile =>
      imageUrl.startsWith('/') || imageUrl.startsWith('file://');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 32,
        maxHeight: 400,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
    try {
      if (isNetworkUrl) {
        // Network image (R2 URLs) with offline fallback
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) {
            // NEW: Try offline fallback when network image fails
            if (note != null) {
              final localPath = note!.getLocalPathForUrl(imageUrl);
              if (localPath != null) {
                final localFile = File(localPath);
                if (localFile.existsSync()) {
                  print(
                    '🔄 Network image failed, using local fallback: $localPath',
                  );
                  return Image.file(
                    localFile,
                    fit: fit,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildErrorWidget('Local fallback failed'),
                  );
                }
              }
            }

            // No fallback available
            return _buildErrorWidget('Failed to load image');
          },
        );
      } else if (isLocalFile) {
        // Local file image
        return Image.file(
          File(imageUrl),
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorWidget('Local image not found'),
        );
      } else {
        // Fallback for unknown format
        return _buildErrorWidget('Unknown image format');
      }
    } catch (e) {
      return _buildErrorWidget('Error: $e');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
