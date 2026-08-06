import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';

/// Official tournament result snapshot shared by the mobile result surfaces.
/// The backend owns podium and standings rules; the app only renders them.
final tournamentResultProvider = StreamProvider.autoDispose.family<
    Map<String, dynamic>, ({String tournamentId, String? divisionId})>((ref, params) async* {
  final dio = ref.read(dioProvider);
  Map<String, dynamic>? lastSnapshot;

  while (true) {
    try {
      final response = await dio.get(
        '/tournaments/${params.tournamentId}/results',
        queryParameters: params.divisionId == null
            ? null
            : {'divisionId': params.divisionId},
      );
      final raw = response.data;
      final data = raw is Map<String, dynamic>
          ? (raw['data'] is Map
              ? Map<String, dynamic>.from(raw['data'] as Map)
              : raw.containsKey('awards')
                  ? Map<String, dynamic>.from(raw)
                  : null)
          : null;
      if (data != null) {
        lastSnapshot = data;
        yield data;
      }
    } catch (_) {
      // Keep the last good snapshot visible during transient API failures.
      if (lastSnapshot == null) rethrow;
    }

    await Future<void>.delayed(const Duration(seconds: 15));
  }
});
