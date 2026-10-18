import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_playback_repository.dart';
import 'package:dio/dio.dart';

/// Nguồn phát trực tiếp của một trận.
///
/// Điểm cốt lõi trước đây nằm ở [LivestreamService]: camera luôn phát qua
/// backend (giữ đường dẫn một chỗ khi đổi nguồn phát). Vì vậy app đọc
/// `playbackUrl` từ đây chứ không tự dựng URL từ stream key — nếu sân đổi
/// giao thức (FLV sang HLS) thì app không phải sửa.
class ApiMatchPlaybackRepository implements IMatchPlaybackRepository {
  ApiMatchPlaybackRepository(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<MatchPlaybackModel> getMatchPlayback(String matchId) async {
    final response = await _dioClient.dio.get<Object?>(
      '/livestream/matches/$matchId/playback',
      options: Options(extra: <String, Object?>{'noCache': true}),
    );
    await _ensureSuccess(response);
    final payload = response.data;
    if (payload is Map && payload['data'] is Map) {
      return MatchPlaybackModel.fromJson(
        Map<String, Object?>.from(payload['data'] as Map),
      );
    }
    throw const FormatException('Phan hoi playback khong hop le');
  }

  Future<void> _ensureSuccess(Response<Object?> response) async {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    if (status == 404) {
      // Trận chưa gắn camera hoặc sân chưa khai URL — đây là trạng thái bình
      // thường khi xem live, không phải lỗi cần hiện cho người dùng.
      return;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: 'Khong tai duoc luong phat (HTTP $status)',
    );
  }
}
