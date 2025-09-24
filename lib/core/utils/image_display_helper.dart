import 'dart:convert';
import 'package:flutter/material.dart';

class ImageDisplayHelper {
  /// Displays an image from a base64 string or URL
  static Widget displayImage(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image/')) {
      try {
        // Extract base64 data
        final base64String = imageUrl.split(',')[1];
        final imageBytes = base64Decode(base64String);
        
        return Image.memory(
          imageBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _defaultErrorWidget();
          },
        );
      } catch (e) {
        print('Error displaying base64 image: $e');
        return errorWidget ?? _defaultErrorWidget();
      }
    } 
    // Handle regular URLs (for future use)
    else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return loadingWidget ?? _defaultLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _defaultErrorWidget();
        },
      );
    }
    // Handle error cases
    else {
      return errorWidget ?? _defaultErrorWidget();
    }
  }

  /// Displays a grid of images from a list of image URLs/base64 strings
  static Widget displayImageGrid(
    List<String> imageUrls, {
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    double? itemWidth,
    double? itemHeight,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              'No images attached',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => _showImageDialog(context, imageUrls[index]),
            child: displayImage(
              imageUrls[index],
              width: itemWidth,
              height: itemHeight,
              fit: fit,
            ),
          ),
        );
      },
    );
  }

  /// Shows an image in a full-screen dialog
  static void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: displayImage(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Default error widget for failed image loads
  static Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Default loading widget for network images
  static Widget _defaultLoadingWidget() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Displays a single image with a nice frame and optional caption
  static Widget displayImageCard(
    BuildContext context,
    String imageUrl, {
    String? caption,
    double? width,
    double? height,
    EdgeInsets? padding,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _showImageDialog(context, imageUrl),
                child: displayImage(
                  imageUrl,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}