import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ImageService {
  final Logger _logger = Logger('ImageService');

  String detectImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'unknown';
    
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    
    // GIF: 47 49 46 38 (GIF87a or GIF89a)
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && 
        (bytes[3] == 0x38 || bytes[3] == 0x37)) {
      return 'gif';
    }
    
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }
    
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    
    // TIFF: 49 49 2A 00 (little endian) or 4D 4D 00 2A (big endian)
    if ((bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) ||
        (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A)) {
      return 'tiff';
    }
    
    // ICO: 00 00 01 00
    if (bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x01 && bytes[3] == 0x00) {
      return 'ico';
    }
    
    // SVG: Check for XML declaration or SVG tag
    if (bytes.length > 10) {
      String header = String.fromCharCodes(bytes.take(10));
      if (header.toLowerCase().contains('<?xml') || header.toLowerCase().contains('<svg')) {
        return 'svg';
      }
    }
    
    // HEIF/HEIC: Check for ftyp box
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
      String ftyp = String.fromCharCodes(bytes.sublist(8, 12));
      if (ftyp.contains('heic') || ftyp.contains('heif') || ftyp.contains('mif1') || ftyp.contains('msf1')) {
        return 'heic';
      }
    }
    
    // AVIF: Check for ftyp box with avif
    if (bytes.length >= 12 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
      String ftyp = String.fromCharCodes(bytes.sublist(8, 12));
      if (ftyp.contains('avif')) {
        return 'avif';
      }
    }
    
    return 'unknown';
  }

  Future<Map<String, dynamic>> getImageInfo(Uint8List bytes) async {
    try {
      final size = bytes.length;
      final image = await decodeImageFromList(bytes);
      final format = detectImageFormat(bytes);
      return {
        'size': size,
        'format': format,
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      _logger.severe('Error getting image info: $e');
      rethrow;
    }
  }

  Future<void> saveImage(Uint8List imageData, String fileName) async {
    // Implement web download logic if needed
    throw UnimplementedError('saveImage is not supported on web');
  }
}
