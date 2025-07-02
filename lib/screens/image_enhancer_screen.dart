import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/image_info_card.dart';
import '../widgets/control_buttons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

class ImageEnhancerScreen extends StatefulWidget {
  const ImageEnhancerScreen({super.key});

  @override
  State<ImageEnhancerScreen> createState() => _ImageEnhancerScreenState();
}

class _ImageEnhancerScreenState extends State<ImageEnhancerScreen> {
  final _apiService = ApiService();

  Uint8List? _selectedImage;
  Uint8List? _enhancedImage;
  Map<String, dynamic>? _imageInfo;
  Map<String, dynamic>? _enhancedImageInfo;
  Map<String, dynamic>? _metrics;
  bool _isLoading = false;
  String? _detectedNoiseType;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      await _apiService.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kết nối thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối đến server: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String detectImageFormat(Uint8List bytes) {
    if (bytes.length > 4) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'png';
      } else if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'jpg';
      } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'gif';
      } else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        return 'bmp';
      }
    }
    return 'unknown';
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImage = result.files.single.bytes;
        _enhancedImage = null;
        _imageInfo = null;
        _metrics = null;
      });
      final image = await decodeImageFromList(_selectedImage!);
      final format = detectImageFormat(_selectedImage!);
      setState(() => _imageInfo = {
        'size': _selectedImage!.length,
        'format': format,
        'width': image.width,
        'height': image.height,
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.enhanceImage(_selectedImage!);
      
      if (result['status'] == 'no_noise_detected') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Thông báo'),
              content: const Text('Ảnh này là ảnh sạch, không cần xử lý!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        setState(() {
          _enhancedImage = null;
          _metrics = null;
          _detectedNoiseType = null;
          _enhancedImageInfo = null;
        });
        return;
      }

      Uint8List tempFile = result['enhanced_image'];
      final originalWidth = _imageInfo?['width'];
      final originalHeight = _imageInfo?['height'];
      final decoded = img.decodeImage(tempFile);
      if (decoded != null && originalWidth != null && originalHeight != null) {
        if (decoded.width != originalWidth || decoded.height != originalHeight) {
          final resized = img.copyResize(decoded, width: originalWidth, height: originalHeight);
          final resizedBytes = img.encodePng(resized);
          tempFile = Uint8List.fromList(resizedBytes);
        }
      }
      setState(() {
        _enhancedImage = tempFile;
        _metrics = result['metrics'];
        _detectedNoiseType = result['detectedNoiseType'];
      });
      final enhancedImage = await decodeImageFromList(_enhancedImage!);
      final enhancedFormat = detectImageFormat(_enhancedImage!);
      setState(() {
        _enhancedImageInfo = {
          'size': _enhancedImage!.length,
          'format': enhancedFormat,
          'width': enhancedImage.width,
          'height': enhancedImage.height,
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã phát hiện và xử lý nhiễu: ${result['detectedNoiseType']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Lỗi khi xử lý ảnh: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveImage() async {
    if (kIsWeb) {
      if (_enhancedImage == null) return;
      _showSuccess('Chức năng tải ảnh chỉ khả dụng trên web');
      return;
    }
  }

  Future<void> _showUrlInputDialog() async {
    final TextEditingController urlDialogController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tải ảnh từ URL'),
        content: TextField(
          controller: urlDialogController,
          decoration: const InputDecoration(
            labelText: 'Nhập URL ảnh',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(urlDialogController.text),
            child: const Text('Tải ảnh'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _loadImageFromUrlCustom(result);
    }
  }

  Future<void> _loadImageFromUrlCustom(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw Exception('URL không hợp lệ');
      }
      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Không thể tải ảnh: ${response.statusCode}');
      }
      final bytes = response.data as List<int>;
      if (bytes.isEmpty) {
        throw Exception('Không nhận được dữ liệu ảnh');
      }
      try {
        final image = await decodeImageFromList(Uint8List.fromList(bytes));
        final format = detectImageFormat(Uint8List.fromList(bytes));
        setState(() {
          _selectedImage = Uint8List.fromList(bytes);
          _enhancedImage = null;
          _imageInfo = {
            'size': bytes.length,
            'format': format,
            'width': image.width,
            'height': image.height,
          };
        });
      } catch (e) {
        throw Exception('Dữ liệu ảnh không hợp lệ');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tải ảnh thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMsg = 'Lỗi: ${e.toString()}';
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        errorMsg = 'Không thể kết nối hoặc bị chặn bởi CORS. Nếu bạn đang chạy trên web, hãy thử một ảnh từ server cho phép truy cập cross-origin.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('Ứng dụng nâng cao chất lượng hình ảnh', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ControlButtons(
                      isLoading: _isLoading,
                      hasImage: _selectedImage != null,
                      onPickImage: _pickImage,
                      onProcessImage: _processImage,
                      onLoadFromUrl: _showUrlInputDialog,
                    ),
                    if (_selectedImage == null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 90,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chưa có ảnh nào được chọn',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    if (_selectedImage != null && _imageInfo != null) ...[
                      Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    tooltip: 'Xoá ảnh',
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _enhancedImage = null;
                                        _imageInfo = null;
                                        _enhancedImageInfo = null;
                                        _metrics = null;
                                        _detectedNoiseType = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _selectedImage!,
                                    height: 220,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_imageInfo != null)
                                ImageInfoCard(
                                  imageInfo: _imageInfo!,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_enhancedImage != null && _enhancedImageInfo != null) ...[
                      Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _enhancedImage!,
                                    height: 220,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_enhancedImageInfo != null)
                                ImageInfoCard(
                                  imageInfo: _enhancedImageInfo!,
                                  metrics: _metrics,
                                  detectedNoiseType: _detectedNoiseType,
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _saveImage,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Lưu'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2196F3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Đang xử lý ảnh...',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 