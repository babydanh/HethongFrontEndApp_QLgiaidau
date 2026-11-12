import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the signed-in ADMIN is also an invited CO_ORGANIZER of
/// [tournamentId], read from that tournament's own staff list
/// (`GET /tournaments/:id/staff`, same source as the Web `useIsCoOrganizer`).
///
/// Only an ADMIN needs this answer: everyone else follows the backend
/// `score-access` verdict, so other roles skip the request. Fails closed
/// (false) while loading, signed out, or when the request fails.
final tournamentCoOrganizerProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, tournamentId) async {
      if (tournamentId.isEmpty) return false;
      if (!ref.watch(authProvider.select((a) => a.isAdmin))) return false;
      final userId = ref.watch(userProfileProvider).asData?.value.id;
      if (userId == null || userId.isEmpty) return false;
      try {
        final staff = await ref
            .watch(tournamentManagementRepositoryProvider)
            .getStaff(tournamentId);
        return staff.any(
          (row) => row['userId'] == userId && row['role'] == 'CO_ORGANIZER',
        );
      } on Object {
        return false;
      }
    });
