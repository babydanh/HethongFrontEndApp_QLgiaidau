import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/services/manage_role_access.dart';

// 404: the Backend hides a DRAFT/PENDING tournament from its referees.
const _deniedStatusCodes = {401, 403, 404};

/// The signed-in user's role on the management page of [tournamentId], or
/// null when the Backend denies access (401/403/404).
///
/// The Backend answers the role on `GET /tournaments/:id?manage=true`
/// (`manageRole`). Any other failure is rethrown so the guard can show a retry
/// instead of guessing.
final tournamentManageAccessProvider = FutureProvider.autoDispose
    .family<ManageRole?, String>((ref, tournamentId) async {
      try {
        return await ref
            .watch(tournamentRepositoryProvider)
            .getManageRole(tournamentId);
      } on DioException catch (error) {
        if (_deniedStatusCodes.contains(error.response?.statusCode)) {
          return null;
        }
        rethrow;
      }
    });
