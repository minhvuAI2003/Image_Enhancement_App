import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'image_info_card.dart';

class ImagePreview extends StatelessWidget {
  final Uint8List? image;
  final Map<String, dynamic>? imageInfo;
  final Map<String, dynamic>? metrics;
  final String? title;
  final bool showActions;
  final VoidCallback? onSave;
  final String? detectedNoiseType;

  const ImagePreview({
    super.key,
    this.image,
    this.imageInfo,
    this.metrics,
    this.title,
    this.showActions = false,
    this.onSave,
    this.detectedNoiseType,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Image.memory(
          image!,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
        ),
        if (imageInfo != null) ...[
          const SizedBox(height: 16),
          ImageInfoCard(
            imageInfo: imageInfo!,
            metrics: metrics,
            detectedNoiseType: detectedNoiseType,
          ),
        ],
        if (showActions && onSave != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu'),
                ),
            ],
          ),
        ],
      ],
    );
  }
} 