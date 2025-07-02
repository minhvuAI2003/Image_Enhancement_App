import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';


class ApiService {
  final Dio _dio;
  final String _baseUrl = 'http://158.101.124.78:3550'; //Thay bằng đường dẫn tới server AI của bạn
  final Logger _logger = Logger('ApiService');

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Add CORS headers for web requests
    if (kIsWeb) {
      _dio.options.headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
      };
    }
  }

  Future<Map<String, dynamic>> testConnection() async {
    try {
      _logger.info('Testing connection to: $_baseUrl');
      
      // Use auto-detect-and-process endpoint for testing
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          [],
          filename: 'test.png',
          contentType: MediaType('image', 'png'),
        ),
      });

      final response = await _dio.post(
        '/auto-detect-and-process',
        data: formData,
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 400) {
        // 400 is expected as we're sending an empty file
        _logger.info('Connection test successful');
        return {'status': 'connected'};
      }
      
      throw Exception('Server response indicates error');
    } on DioException catch (e) {
      _logger.severe('Connection test failed: ${e.message}');
      if (kIsWeb) {
        _logger.info('Note: If running in web browser, ensure CORS is enabled on the server');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> autoDetectAndProcess(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ext = path.extension(imageFile.path).toLowerCase();
      String mimeType = 'png';
      if (ext == '.jpg' || ext == '.jpeg') mimeType = 'jpeg';
      else if (ext == '.bmp') mimeType = 'bmp';
      else if (ext == '.gif') mimeType = 'gif';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'image.${ext}',
          contentType: MediaType('image', mimeType),
        ),
      });

      _logger.info('Sending request for auto detection and processing: ${imageFile.path}');
      
      final response = await _dio.post(
        '/auto-detect-and-process',
        data: formData,
        options: Options(
          validateStatus: (status) => true,
          headers: {
            'Accept': 'image/png',
            'Content-Type': 'multipart/form-data',
          },
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200) {
        // Check if the response is a JSON indicating no noise detected
        if (response.headers.value('content-type')?.contains('application/json') ?? false) {
          final jsonResponse = response.data as Map<String, dynamic>;
          return {
            'status': jsonResponse['status'],
            'message': jsonResponse['message'],
          };
        }

        // Process successful image enhancement response
        final psnr = double.tryParse(response.headers.value('X-PSNR') ?? '0') ?? 0.0;
        final ssim = double.tryParse(response.headers.value('X-SSIM') ?? '0') ?? 0.0;
        final detectedNoiseType = response.headers.value('X-Detected-Noise-Type');
        
        return {
          'imageData': response.data,
          'metrics': {
            'psnr': psnr,
            'ssim': ssim,
          },
          'detectedNoiseType': detectedNoiseType,
        };
      } else {
        final errorMessage = response.data is List 
            ? String.fromCharCodes(response.data)
            : response.data.toString();
        _logger.severe('Server error: ${response.statusCode} - $errorMessage');
        throw Exception('Server error: ${response.statusCode} - $errorMessage');
      }
    } on DioException catch (e) {
      _logger.severe('Error processing image: ${e.message}');
      if (e.response?.data != null) {
        final errorMessage = e.response!.data is List 
            ? String.fromCharCodes(e.response!.data)
            : e.response!.data.toString();
        throw Exception('Server error: ${e.response!.statusCode} - $errorMessage');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processImage(
    File imageFile,
    String task,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ext = path.extension(imageFile.path).toLowerCase();
      String mimeType = 'png';
      if (ext == '.jpg' || ext == '.jpeg') mimeType = 'jpeg';
      else if (ext == '.bmp') mimeType = 'bmp';
      else if (ext == '.gif') mimeType = 'gif';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'image.${ext}',
          contentType: MediaType('image', mimeType),
        ),
      });

      String endpoint;
      endpoint = '/$task';
      _logger.info('Sending request to: $endpoint with file: ${imageFile.path}');
      
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          validateStatus: (status) => true,
          headers: {
            'Accept': 'image/png',
            'Content-Type': 'multipart/form-data',
          },
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200) {
        final psnr = double.tryParse(response.headers.value('X-PSNR') ?? '0') ?? 0.0;
        final ssim = double.tryParse(response.headers.value('X-SSIM') ?? '0') ?? 0.0;
        
        return {
          'imageData': response.data,
          'metrics': {
            'psnr': psnr,
            'ssim': ssim,
          },
        };
      } else {
        final errorMessage = response.data is List 
            ? String.fromCharCodes(response.data)
            : response.data.toString();
        _logger.severe('Server error: ${response.statusCode} - $errorMessage');
        throw Exception('Server error: ${response.statusCode} - $errorMessage');
      }
    } on DioException catch (e) {
      _logger.severe('Error processing image: ${e.message}');
      if (e.response?.data != null) {
        final errorMessage = e.response!.data is List 
            ? String.fromCharCodes(e.response!.data)
            : e.response!.data.toString();
        throw Exception('Server error: ${e.response!.statusCode} - $errorMessage');
      }
      rethrow;
    }
  }

  Future<List<int>> loadImageFromUrl(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as List<int>;
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('Error loading image from URL: ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> enhanceImage(Uint8List imageBytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'image.png',
          contentType: MediaType('image', 'png'),
        ),
      });
      final response = await _dio.post(
        '/auto-detect-and-process',
        data: formData,
        options: Options(
          validateStatus: (status) => true,
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );
      if (response.statusCode == 200) {
        // Nếu là JSON (ảnh sạch)
        if (response.headers.value('content-type')?.contains('application/json') ?? false) {
          final jsonResponse = jsonDecode(utf8.decode(response.data));
          return {
            'status': jsonResponse['status'],
            'message': jsonResponse['message'],
          };
        }
        // Nếu là ảnh thực sự
        // Log all response headers for debugging
        _logger.info('Response headers: ${response.headers.map}');
        final psnrHeader = response.headers.value('X-PSNR');
        final ssimHeader = response.headers.value('X-SSIM');
        _logger.info('PSNR header: $psnrHeader');
        _logger.info('SSIM header: $ssimHeader');
        final psnr = double.tryParse(psnrHeader ?? '0') ?? 0.0;
        final ssim = double.tryParse(ssimHeader ?? '0') ?? 0.0;
        final detectedNoiseType = response.headers.value('X-Detected-Noise-Type');
        _logger.info('Parsed metrics - PSNR: $psnr, SSIM: $ssim');
        return {
          'enhanced_image': response.data,
          'metrics': {
            'psnr': double.parse(psnr.toStringAsFixed(2)),
            'ssim': double.parse(ssim.toStringAsFixed(2)),
          },
          'detectedNoiseType': detectedNoiseType,
        };
      } else {
        final errorMessage = response.data is List 
            ? String.fromCharCodes(response.data)
            : response.data.toString();
        _logger.severe('Server error: ${response.statusCode} - $errorMessage');
        throw Exception('Server error: ${response.statusCode} - $errorMessage');
      }
    } on DioException catch (e) {
      _logger.severe('Error processing image: ${e.message}');
      if (e.response?.data != null) {
        final errorMessage = e.response!.data is List 
            ? String.fromCharCodes(e.response!.data)
            : e.response!.data.toString();
        throw Exception('Server error: ${e.response!.statusCode} - $errorMessage');
      }
      rethrow;
    }
  }

  Future<void> shareImage(Uint8List imageBytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'image.png',
          contentType: MediaType('image', 'png'),
        ),
      });
      final response = await _dio.post(
        '/share',
        data: formData,
        options: Options(
          validateStatus: (status) => status! < 500,
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['detail'] ?? 'Lỗi khi chia sẻ ảnh');
      }
    } on DioException catch (e) {
      _logger.severe('Error sharing image: ${e.message}');
      rethrow;
    }
  }
} 