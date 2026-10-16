// Generated Flutter / Dart API Service
// Spec: Tournament Platform API v1.0.0
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final Map<String, String>? headers;

  ApiService({required this.baseUrl, this.headers});

  /// Lấy danh sách các giải đấu
  Future<dynamic> getTournaments({Map<String, dynamic>? query}) async {
    final uri = Uri.parse('$baseUrl/api/v1/tournaments').replace(queryParameters: query);
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('API GET /api/v1/tournaments failed: ${response.statusCode}');
  }

  /// Tạo giải đấu mới
  Future<dynamic> createTournament({Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/api/v1/tournaments');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('API POST /api/v1/tournaments failed: ${response.statusCode}');
  }

  /// Chi tiết giải đấu
  Future<dynamic> getTournamentById({required String id}) async {
    final uri = Uri.parse('$baseUrl/api/v1/tournaments/$id');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('API GET /api/v1/tournaments/{id} failed: ${response.statusCode}');
  }

  /// Đăng ký tham gia giải đấu
  Future<dynamic> joinTournament({required String id, Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/api/v1/tournaments/$id/join');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('API POST /api/v1/tournaments/{id}/join failed: ${response.statusCode}');
  }

  /// Cập nhật tỉ số trận đấu
  Future<dynamic> updateMatchScore({required String id, Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl/api/v1/matches/$id/score');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('API PUT /api/v1/matches/{id}/score failed: ${response.statusCode}');
  }
}
