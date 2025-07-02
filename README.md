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
- Hệ điều hành: Windows, macOS, Linux, Web, Android, iOS

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

## Sử dụng
- Nhấn **Chọn ảnh** để tải ảnh từ thiết bị hoặc **Tải ảnh từ URL** để nhập link ảnh.
- Nhấn **Xử lý ảnh** để ứng dụng tự động phát hiện và nâng cao chất lượng ảnh.
- Xem thông tin ảnh gốc và ảnh đã xử lý.
- Lưu ảnh kết quả về máy.

## Backend/Server
- Ứng dụng sử dụng server AI tại địa chỉ: `http://158.101.124.78:3550`
- Nếu muốn tự triển khai server, hãy thay đổi biến `_baseUrl` trong `lib/services/api_service.dart`.

## Phụ thuộc chính
- [dio](https://pub.dev/packages/dio)
- [file_picker](https://pub.dev/packages/file_picker)
- [image](https://pub.dev/packages/image)
- [http](https://pub.dev/packages/http)
- [logging](https://pub.dev/packages/logging)
- [share_plus](https://pub.dev/packages/share_plus)
- [shared_preferences](https://pub.dev/packages/shared_preferences)

## Đóng góp
Mọi đóng góp, báo lỗi hoặc ý tưởng mới đều được hoan nghênh! Hãy tạo issue hoặc pull request.

---

> Ứng dụng này dành cho mục đích học tập và demo. Nếu sử dụng cho mục đích thương mại, hãy kiểm tra lại bản quyền các mô hình AI phía server.