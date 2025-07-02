# Image Enhancement App

Ứng dụng Flutter nâng cao chất lượng hình ảnh bằng cách phát hiện và xử lý các loại nhiễu/mờ phổ biến. Ứng dụng kết nối tới server AI để tự động nhận diện và cải thiện ảnh.

## Tính năng chính
- Chọn ảnh từ thiết bị hoặc nhập URL ảnh
- Tự động phát hiện loại nhiễu/mờ (nhiễu Gauss, mưa, mờ chuyển động, mờ tiêu cự, nhiễu thực tế)
- Xử lý và nâng cao chất lượng ảnh bằng AI
- Hiển thị thông tin ảnh trước/sau xử lý (kích thước, định dạng, độ phân giải, PSNR, SSIM)
- Lưu ảnh kết quả về thiết bị
- Giao diện hiện đại, dễ sử dụng

## Yêu cầu hệ thống
- Flutter SDK >= 3.0.0 < 4.0.0

## Cài đặt
1. Clone repo:
   ```bash
   git clone https://github.com/minhvuAI2003/Image_Enhancement_App.git
   cd Image_Enhancement_App
   ```
2. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng:
   ```bash
   flutter run -d chrome
   ```


## Backend/Server
- Ứng dụng cần kết nối tới một server AI để xử lý ảnh.
- Bạn cần điền đường dẫn server AI  vào biến `_baseUrl` trong file `lib/services/api_service.dart` (ví dụ: `http://<ip-hoặc-domain>:<port>`).



