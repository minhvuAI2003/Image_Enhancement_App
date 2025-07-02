import 'package:flutter/material.dart';

class ImageInfoCard extends StatelessWidget {
  final Map<String, dynamic> imageInfo;
  final Map<String, dynamic>? metrics;
  final String? detectedNoiseType;

  const ImageInfoCard({
    super.key,
    required this.imageInfo,
    this.metrics,
    this.detectedNoiseType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin ảnh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Kích thước', '${imageInfo['size']} KB'),
            _buildInfoRow('Định dạng', imageInfo['format']),
            _buildInfoRow('Kích thước', '${imageInfo['width']}x${imageInfo['height']}'),
            if (detectedNoiseType != null) ...[
              const Divider(),
              const Text(
                'Loại xử lý',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Phát hiện', _formatNoiseType(detectedNoiseType!)),
            ],
            if (metrics != null) ...[
              const Divider(),
              const Text(
                'Chất lượng ảnh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Độ trung thực (PSNR)', metrics!['psnr'] != null ? metrics!['psnr'].toString() : ''),
              _buildInfoRow('Độ tương đồng cấu trúc (SSIM)', metrics!['ssim'] != null ? metrics!['ssim'].toString() : ''),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNoiseType(String type) {
    switch (type) {
      case 'gaussian_denoise':
        return 'Nhiễu Gauss';
      case 'motion_deblur':
        return 'Mờ chuyển động';
      case 'derain':
        return 'Mưa';
      case 'real_denoise':
        return 'Nhiễu thực tế';
      case 'single_image_deblur':
        return 'Mờ tiêu cự';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
} 