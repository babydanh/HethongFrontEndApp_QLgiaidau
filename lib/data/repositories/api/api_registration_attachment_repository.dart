import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/repositories/registration_attachment_repository.dart';
import 'package:dio/dio.dart';

class ApiRegistrationAttachmentRepository
    implements IRegistrationAttachmentRepository {
  final DioClient _dioClient;

  ApiRegistrationAttachmentRepository(this._dioClient);

  @override
  Future<Map<String, dynamic>> upload({
    required String tournamentId,
    required String fieldId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final response = await _dioClient.dio.post(
      '/tournaments/$tournamentId/registration-attachment',
      data: FormData.fromMap({
        'fieldId': fieldId,
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    final body = response.data;
    final raw = body is Map && body['data'] is Map ? body['data'] : body;
    if (raw is! Map || raw['url'] is! String) {
      throw const FormatException('Missing attachment url in response');
    }
    return Map<String, dynamic>.from(raw);
  }
}
