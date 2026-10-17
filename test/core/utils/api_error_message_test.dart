import 'package:app_quanly_giaidau/core/utils/api_error_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dioError(Object? data, {int status = 400}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  test('returns the backend message verbatim', () {
    final error = _dioError({
      'status': 'ERROR',
      'message': 'Vui lòng chọn nội dung để ghép đôi.',
    });
    expect(
      backendErrorMessage(error),
      'Vui lòng chọn nội dung để ghép đôi.',
    );
  });

  test('joins validation message lists', () {
    expect(backendErrorMessage(_dioError({'message': 'a'})), 'a');
    expect(
      backendErrorMessage(
        _dioError({
          'message': ['a', 'b'],
        }),
      ),
      'a; b',
    );
  });

  test('returns null when there is no usable backend message', () {
    expect(backendErrorMessage(_dioError({'status': 'ERROR'})), isNull);
    expect(backendErrorMessage(_dioError('plain text')), isNull);
    expect(backendErrorMessage(_dioError({'message': '   '})), isNull);
    expect(backendErrorMessage(StateError('x')), isNull);
    expect(backendErrorMessage(null), isNull);
  });
}
