import 'dart:developer' as developer;

/// Logger tập trung cho toàn bộ ứng dụng.
///
/// Sử dụng `dart:developer` log() thay vì print() để:
/// - Có thể lọc theo tag trong DevTools
/// - Hỗ trợ stack trace cho errors
/// - Dễ dàng thay thế bằng package khác (logger, talker, etc.)
///
/// Cách dùng:
/// ```dart
/// class MyRepository {
///   static const _log = AppLogger('MyRepository');
///
///   Future<void> doSomething() async {
///     _log.info('Bắt đầu doSomething');
///     try {
///       // ... logic
///       _log.success('doSomething thành công');
///     } catch (e, stack) {
///       _log.error('Lỗi doSomething', e, stack);
///       rethrow;
///     }
///   }
/// }
/// ```
class AppLogger {
  final String _tag;

  const AppLogger(this._tag);

  /// Log thông tin debug chi tiết (chỉ dùng khi cần trace)
  void debug(String message) {
    developer.log('💬 $message', name: _tag);
  }

  /// Log bắt đầu tác vụ quan trọng
  void info(String message) {
    developer.log('ℹ️ $message', name: _tag);
  }

  /// Log trường hợp bất thường nhưng không crash
  void warning(String message) {
    developer.log('⚠️ $message', name: _tag);
  }

  /// Log lỗi nghiêm trọng, kèm error object và stack trace
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '❌ $message',
      name: _tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log tác vụ hoàn thành thành công
  void success(String message) {
    developer.log('✅ $message', name: _tag);
  }
}
