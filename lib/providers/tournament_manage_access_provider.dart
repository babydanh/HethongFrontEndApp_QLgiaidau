import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';

const _deniedStatusCodes = {401, 403};

/// Whether the signed-in user may manage/operate [tournamentId].
///
/// The public tournament payload does not say who may manage, so ask an
/// organizer-only endpoint once: 401/403 means denied. Any other failure is
/// rethrown so the guard can show a retry instead of guessing.
final tournamentManageAccessProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, tournamentId) async {
      try {
        await ref
            .watch(tournamentRepositoryProvider)
            .getOrganizerParticipants(tournamentId);
        return true;
      } on DioException catch (error) {
        if (_deniedStatusCodes.contains(error.response?.statusCode)) {
          return false;
        }
        rethrow;
      }
    });
