import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/providers/query_providers.dart';

/// True when the tournament collects its entry fee directly (organizer),
/// so the app must never start a platform payment for it.
///
/// Fails open (false = PAYOS) when the tournament cannot be loaded; the
/// backend still rejects registration-fee payment links in DIRECT mode.
Future<bool> isDirectFeeTournament(WidgetRef ref, String tournamentId) async {
  if (tournamentId.isEmpty) return false;
  try {
    final tournament = await ref.read(tournamentProvider(tournamentId).future);
    return tournament?.isDirectFeeCollection ?? false;
  } catch (_) {
    return false;
  }
}
