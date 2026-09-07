import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clubMatchSessionRepositoryProvider =
    Provider<ApiClubMatchSessionRepository>((ref) {
      return ApiClubMatchSessionRepository(ref.watch(dioClientProvider));
    });

class ClubMatchSessionsNotifier
    extends AsyncNotifier<List<ClubMatchSessionModel>> {
  final String communityId;
  ClubMatchSessionsNotifier(this.communityId);

  @override
  Future<List<ClubMatchSessionModel>> build() =>
      ref.read(clubMatchSessionRepositoryProvider).list(communityId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(clubMatchSessionRepositoryProvider).list(communityId),
    );
  }

  Future<ClubMatchSessionModel> create({
    String? name,
    String? description,
    required String registrationMode,
    required bool isRanked,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final created = await ref
        .read(clubMatchSessionRepositoryProvider)
        .create(
          communityId: communityId,
          name: name,
          description: description,
          registrationMode: registrationMode,
          isRanked: isRanked,
          startAt: startAt,
          endAt: endAt,
        );
    await refresh();
    return created;
  }
}

final clubMatchSessionsProvider =
    AsyncNotifierProvider.family<
      ClubMatchSessionsNotifier,
      List<ClubMatchSessionModel>,
      String
    >(ClubMatchSessionsNotifier.new);

typedef ClubSessionDetail = ({
  ClubMatchSessionModel session,
  List<ClubMatchParticipantModel> participants,
  List<ClubSessionMatchModel> matches,
});

final clubSessionDetailProvider =
    FutureProvider.family<ClubSessionDetail, String>((ref, sessionId) async {
      final repository = ref.read(clubMatchSessionRepositoryProvider);
      final values = await Future.wait([
        repository.get(sessionId),
        repository.participants(sessionId),
        repository.matches(sessionId),
      ]);
      return (
        session: values[0] as ClubMatchSessionModel,
        participants: values[1] as List<ClubMatchParticipantModel>,
        matches: values[2] as List<ClubSessionMatchModel>,
      );
    });
