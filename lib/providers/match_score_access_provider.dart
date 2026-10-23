import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backend verdict on whether the signed-in user may score [matchId]
/// (`GET /matches/:id/score-access`).
///
/// Returns `null` when the answer is unknown (network error, 401/403, odd
/// payload) so callers can fall back to the owner/referee rule instead of
/// opening the scoring panel on a guess.
///
/// Auto-disposed and tied to the sign-in state so one account's answer (or a
/// transient failure) is never reused for another session.
final matchScoreAccessProvider = FutureProvider.autoDispose
    .family<bool?, String>((ref, matchId) async {
  if (matchId.isEmpty) return null;
  if (!ref.watch(authProvider.select((a) => a.isAuthenticated))) return null;
  try {
    final response = await ref
        .watch(dioClientProvider)
        .dio
        .get<Object?>(
          '/matches/$matchId/score-access',
          options: Options(extra: <String, Object?>{'noCache': true}),
        );
    final payload = response.data;
    if (payload is! Map) return null;
    final body = payload['data'] is Map ? payload['data'] as Map : payload;
    final canScore = body['canScore'];
    return canScore is bool ? canScore : null;
  } on Object {
    return null;
  }
});
