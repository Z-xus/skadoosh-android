import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skadoosh_app/services/image_cache_service.dart';

class CachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Try to get cached image first
      File? cachedFile = await ImageCacheService.instance.getCachedImage(
        widget.imageUrl,
      );

      if (cachedFile != null) {
        setState(() {
          _cachedFile = cachedFile;
          _isLoading = false;
        });
        return;
      }

      // If not cached, download and cache
      cachedFile = await ImageCacheService.instance.downloadAndCacheImage(
        widget.imageUrl,
      );

      if (cachedFile != null && mounted) {
        setState(() {
          _cachedFile = cachedFile;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    if (_hasError || _cachedFile == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
          );
    }

    return Image.file(
      _cachedFile!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 50,
              ),
            );
      },
    );
  }
}

// Enhanced Note Images Widget that uses cached images
class CachedNoteImagesWidget extends StatefulWidget {
  final String noteId;
  final List<String> imageUrls;
  final Function(String imageUrl) onImageRemoved;
  final int maxDisplayCount;

  const CachedNoteImagesWidget({
    super.key,
    required this.noteId,
    required this.imageUrls,
    required this.onImageRemoved,
    this.maxDisplayCount = 4,
  });

  @override
  State<CachedNoteImagesWidget> createState() => _CachedNoteImagesWidgetState();
}

class _CachedNoteImagesWidgetState extends State<CachedNoteImagesWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${widget.imageUrls.length} ${widget.imageUrls.length == 1 ? 'image' : 'images'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildImageGrid(),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final displayUrls = widget.imageUrls.take(widget.maxDisplayCount).toList();
    final remainingCount = widget.imageUrls.length - widget.maxDisplayCount;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        ...displayUrls.asMap().entries.map((entry) {
          final index = entry.key;
          final imageUrl = entry.value;

          if (index == widget.maxDisplayCount - 1 && remainingCount > 0) {
            return _buildOverflowThumbnail(imageUrl, remainingCount);
          } else {
            return _buildImageThumbnail(imageUrl);
          }
        }),
      ],
    );
  }

  Widget _buildImageThumbnail(String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullImage(imageUrl),
      onLongPress: () => _showDeleteDialog(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverflowThumbnail(String imageUrl, int remainingCount) {
    return GestureDetector(
      onTap: () => _showAllImages(),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: const Center(
                      child: Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllImages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGridPage(
          imageUrls: widget.imageUrls,
          onImageRemoved: widget.onImageRemoved,
        ),
      ),
    );
  }

  void _showDeleteDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onImageRemoved(imageUrl);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

// Full-screen image grid page
class ImageGridPage extends StatelessWidget {
  final List<String> imageUrls;
  final Function(String imageUrl) onImageRemoved;

  const ImageGridPage({
    super.key,
    required this.imageUrls,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Images (${imageUrls.length})'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];
          return GestureDetector(
            onTap: () => _showFullImage(context, imageUrl),
            onLongPress: () => _showDeleteDialog(context, imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the grid page too
                onImageRemoved(imageUrl);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
