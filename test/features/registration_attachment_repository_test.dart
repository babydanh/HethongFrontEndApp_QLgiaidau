import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_registration_attachment_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Records every request and answers with [handler].
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

({ApiRegistrationAttachmentRepository repo, _RecordingAdapter adapter}) _build(
  ResponseBody Function(RequestOptions options) handler,
) {
  final adapter = _RecordingAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return (
    repo: ApiRegistrationAttachmentRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    ),
    adapter: adapter,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  const attachment = {
    'url': 'https://res.cloudinary.test/a.pdf',
    'publicId': 'tournahub/registration-attachments/a',
    'originalName': 'a.pdf',
    'size': 3,
    'mimeType': 'application/pdf',
  };

  // TC-REGATTACH-01
  test('upload posts multipart file + fieldId and unwraps the data', () async {
    final t = _build((_) => _json({'statusCode': 201, 'data': attachment}));

    final result = await t.repo.upload(
      tournamentId: 'tour-1',
      fieldId: 'field-9',
      bytes: [1, 2, 3],
      fileName: 'a.pdf',
    );

    expect(result, attachment);
    final request = t.adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/tournaments/tour-1/registration-attachment');
    expect(request.contentType, startsWith('multipart/form-data'));
    final form = request.data as FormData;
    expect(form.fields.map((e) => '${e.key}=${e.value}'), ['fieldId=field-9']);
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'a.pdf');
    expect(form.files.single.value.length, 3);
  });

  // TC-REGATTACH-01b
  test('upload surfaces the HTTP status so the UI can react to 413', () async {
    final t = _build((_) => _json({'message': 'too big'}, 413));

    await expectLater(
      t.repo.upload(
        tournamentId: 'tour-1',
        fieldId: 'f',
        bytes: [1],
        fileName: 'a.pdf',
      ),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          413,
        ),
      ),
    );
  });

  // TC-REGATTACH-01c
  test('upload rejects a response without a stored url', () async {
    final t = _build((_) => _json({'statusCode': 201, 'data': {}}));

    await expectLater(
      t.repo.upload(
        tournamentId: 'tour-1',
        fieldId: 'f',
        bytes: [1],
        fileName: 'a.pdf',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
