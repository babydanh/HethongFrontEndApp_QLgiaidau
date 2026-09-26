import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participants_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('host sees pending requests with slot count and decisions', (
    tester,
  ) async {
    final repository = _FakeSocialSessionRepository();
    await tester.pumpWidget(_app(repository, isHost: true));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 1);
    expect(find.text('Player One'), findsOneWidget);
    expect(find.text('Số chỗ: 2'), findsOneWidget);
    expect(find.byTooltip('Chấp nhận'), findsOneWidget);
    expect(find.byTooltip('Từ chối'), findsOneWidget);
  });

  testWidgets('non-host does not load or see the host request queue', (
    tester,
  ) async {
    final repository = _FakeSocialSessionRepository();
    await tester.pumpWidget(_app(repository, isHost: false));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 0);
    expect(find.text('Yêu cầu tham gia • 1'), findsNothing);
    expect(find.text('Player One'), findsNothing);
  });
}

Widget _app(_FakeSocialSessionRepository repository, {required bool isHost}) {
  return ProviderScope(
    overrides: [socialSessionRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SocialParticipantsTab(
          session: SocialSessionModel(
            id: 'session-1',
            hostUserId: 'host-1',
            title: 'Open play',
            playFormat: 'Giao lưu',
            startAt: DateTime.utc(2026, 10, 1),
            venueName: 'Venue',
            venueAddress: 'Address',
            sport: 'pickleball',
            sportName: 'Pickleball',
          ),
          isHost: isHost,
          onAddParticipant: (_) {},
        ),
      ),
    ),
  );
}

class _FakeSocialSessionRepository implements ISocialSessionRepository {
  int listCalls = 0;

  @override
  Future<SocialJoinRequestListResponse> listJoinRequests(
    String sessionId, {
    int page = 1,
    int limit = 20,
  }) async {
    listCalls++;
    return SocialJoinRequestListResponse(
      items: [
        SocialParticipantModel(
          id: 'participant-1',
          sessionId: sessionId,
          userId: 'player-1',
          fullName: 'Player One',
          status: 'REQUESTED',
          ticketCount: 2,
          joinedAt: DateTime.utc(2026, 9, 26),
          requestedAt: DateTime.utc(2026, 9, 26),
        ),
      ],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
