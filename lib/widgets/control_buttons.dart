import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isLoading;
  final bool hasImage;
  final VoidCallback onPickImage;
  final VoidCallback onProcessImage;
  final VoidCallback onLoadFromUrl;

  const ControlButtons({
    super.key,
    required this.isLoading,
    required this.hasImage,
    required this.onPickImage,
    required this.onProcessImage,
    required this.onLoadFromUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : onPickImage,
          icon: const Icon(Icons.image),
          label: const Text('Chọn ảnh'),
        ),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onLoadFromUrl,
          icon: const Icon(Icons.link),
          label: const Text('Tải ảnh từ URL'),
        ),
        ElevatedButton.icon(
          onPressed: (isLoading || !hasImage) ? null : onProcessImage,
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Xử lý ảnh'),
        ),
      ],
    );
  }
} 