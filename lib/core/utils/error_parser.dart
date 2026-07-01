import 'package:dio/dio.dart';

class ErrorParser {
  /// Chuyển đổi lỗi DioException hoặc các lỗi khác thành thông báo tiếng Việt thân thiện với người dùng
  static String parse(dynamic error, [String fallback = 'Đã xảy ra lỗi hệ thống']) {
    if (error is! DioException) {
      if (error is Exception) {
        return error.toString().replaceFirst('Exception: ', '');
      }
      return fallback;
    }

    final e = error;
    
    // 1. Kiểm tra nếu có phản hồi lỗi chi tiết từ NestJS Server
    if (e.response?.data != null) {
      final responseData = e.response!.data;
      if (responseData is Map<String, dynamic>) {
        final rawMessage = responseData['message'];
        String? msg;
        if (rawMessage is List && rawMessage.isNotEmpty) {
          msg = rawMessage.first.toString();
        } else if (rawMessage is String) {
          msg = rawMessage;
        }

        if (msg != null) {
          // Ánh xạ lỗi hệ thống sang tiếng Việt
          const viMap = {
            'Email already exists': 'Email này đã được đăng ký. Vui lòng dùng email khác hoặc đăng nhập.',
            'email should not be empty': 'Vui lòng nhập địa chỉ email.',
            'email must be an email': 'Địa chỉ email không hợp lệ.',
            'password must be longer than or equal to 6 characters': 'Mật khẩu phải có ít nhất 6 ký tự.',
            'password should not be empty': 'Vui lòng nhập mật khẩu.',
            'fullName should not be empty': 'Vui lòng nhập họ và tên.',
            'Invalid credentials': 'Email hoặc mật khẩu không đúng.',
            'Tài khoản này được đăng ký qua Google. Vui lòng đăng nhập bằng Google.': 'Tài khoản này đã đăng ký qua Google. Vui lòng đăng nhập bằng Google.',
          };
          return viMap[msg] ?? msg;
        }
      }
    }

    // 2. Xử lý các loại lỗi mạng và kết nối từ Dio
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối tới máy chủ quá hạn. Vui lòng kiểm tra lại đường truyền và thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng hoặc server.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 400) return 'Yêu cầu gửi đi không hợp lệ (Lỗi 400).';
        if (code == 401) return 'Email hoặc mật khẩu không chính xác.';
        if (code == 403) return 'Bạn không có quyền thực hiện hành động này.';
        if (code == 404) return 'Không tìm thấy tài nguyên được yêu cầu (Lỗi 404).';
        if (code != null && code >= 500) return 'Lỗi hệ thống phía máy chủ (Lỗi $code).';
        return 'Máy chủ phản hồi mã lỗi (Lỗi $code).';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy bỏ.';
      case DioExceptionType.unknown:
      default:
        // Bắt lỗi XMLHttpRequest onError trên Flutter Web (thường là lỗi CORS hoặc server ngưng hoạt động)
        final errMsg = e.message ?? '';
        if (errMsg.contains('XMLHttpRequest') || errMsg.contains('onError') || errMsg.contains('connection')) {
          return 'Không thể kết nối tới máy chủ (Có thể do lỗi mạng, CORS hoặc server chưa hoạt động).';
        }
        return fallback;
    }
  }
}
