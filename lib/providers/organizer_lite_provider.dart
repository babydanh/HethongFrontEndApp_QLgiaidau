import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_lite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final organizerLiteRefereesProvider =
    FutureProvider.family<List<OrganizerLiteReferee>, String>((ref, tournamentId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/tournaments/$tournamentId/referees');
  final raw = response.data;
  final data = raw is Map<String, dynamic>
      ? (raw['data'] as List<dynamic>? ?? const [])
      : (raw as List<dynamic>? ?? const []);

  return data
      .whereType<Map<String, dynamic>>()
      .map(OrganizerLiteReferee.fromJson)
      .toList();
});
