import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/home_skeletons.dart';
import 'package:app_quanly_giaidau/providers/home_match_feed_provider.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Page = ({List<MatchModel> matches, String? nextCursor});

void main() {
  testWidgets('card shows the page it is given without calling the repository', (
    tester,
  ) async {
    _phone(tester);
    final repository = _PagedMatchRepository({
      null: (matches: [_visibleMatch], nextCursor: 'a'),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(repository.requests, isEmpty);
    expect(find.text('Team Alpha'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('next page shows a skeleton while loading, then its matches', (
    tester,
  ) async {
    _phone(tester);
    final gate = Completer<void>();
    final repository = _PagedMatchRepository({
      null: (matches: [_visibleMatch], nextCursor: 'a'),
      'a': (matches: [_secondPageMatch], nextCursor: null),
    })..gate = gate;

    await tester.pumpWidget(_cardApp(repository));
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();

    expect(repository.requests, ['a']);
    expect(find.byType(TournamentMatchRowsSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(TournamentMatchRowsSkeleton), findsNothing);
    expect(find.text('Second Page Team'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a next page with only placeholders keeps the current page', (
    tester,
  ) async {
    _phone(tester);
    final repository = _PagedMatchRepository({
      null: (matches: [_visibleMatch], nextCursor: 'a'),
      'a': (matches: [_placeholderMatch], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();

    expect(repository.requests, ['a']);
    expect(find.text(_tournament.name.toUpperCase()), findsOneWidget);
    expect(find.text('Team Alpha'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed next page keeps the current page and offers retry', (
    tester,
  ) async {
    _phone(tester);
    final repository = _PagedMatchRepository({
      null: (matches: [_visibleMatch], nextCursor: 'a'),
      'a': (matches: [_secondPageMatch], nextCursor: null),
    })..failOnce = true;

    await tester.pumpWidget(_cardApp(repository));
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Team Alpha'), findsWidgets);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();

    expect(repository.requests, ['a', 'a']);
    expect(find.text('Second Page Team'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('match rows show each athlete photo once, initials otherwise', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const photo = 'https://example.test/alpha.png';
    // Payload thật lặp cùng một thành viên nhiều lần; chuẩn hiển thị chỉ
    // render ảnh một lần cho mỗi VĐV sau khi lọc trùng.
    final match = MatchModel(
      id: 'photo-match',
      tournamentId: _tournament.id,
      round: 1,
      matchNumber: 1,
      team1Id: 'team-alpha-id',
      team2Id: 'team-beta-id',
      team1Name: 'Minh Anh / Quốc Bảo',
      team2Name: 'Team Beta',
      status: 'scheduled',
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 9, 27),
      team1MemberInfos: const [
        MatchMemberInfo(
          userId: 'user-alpha',
          fullName: 'Minh Anh',
          avatarUrl: photo,
        ),
        MatchMemberInfo(userId: 'user-bao', fullName: 'Quốc Bảo'),
        MatchMemberInfo(
          userId: 'user-alpha',
          fullName: 'Minh Anh',
          avatarUrl: photo,
        ),
      ],
      team2MemberInfos: const [
        MatchMemberInfo(userId: 'user-beta', fullName: 'Team Beta'),
      ],
    );
    final repository = _PagedMatchRepository({
      null: (matches: [match], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    final photos = find.byWidgetPredicate(
      (widget) =>
          widget is CircleAvatar &&
          widget.backgroundImage is NetworkImage &&
          (widget.backgroundImage as NetworkImage).url == photo,
    );
    expect(photos, findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public explore card never shows the organizer match code', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final match = MatchModel(
      id: 'code-match',
      tournamentId: _tournament.id,
      round: 1,
      matchNumber: 1,
      matchCode: 'TK01',
      team1Id: 'team-alpha-id',
      team2Id: 'team-beta-id',
      team1Name: 'Team Alpha',
      team2Name: 'Team Beta',
      status: 'scheduled',
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 9, 27),
    );
    final repository = _PagedMatchRepository({
      null: (matches: [match], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(find.textContaining('TK01'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pair whose team name differs from API order shows the team name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const linhPhoto = 'https://example.test/linh.png';
    // API trả Hoang Linh trước, nhưng tên đội đặt Quy Dương trước: chuẩn
    // hiển thị ưu tiên tên đội (avatar chỉ render khi tên khớp thứ tự API).
    final match = MatchModel(
      id: 'pair-match',
      tournamentId: _tournament.id,
      round: 1,
      matchNumber: 1,
      team1Id: 'team-alpha-id',
      team2Id: 'team-pair-id',
      team1Name: 'Team Alpha',
      team2Name: 'Quy Dương / Hoang Linh',
      status: 'scheduled',
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 9, 27),
      team2MemberInfos: const [
        MatchMemberInfo(
          userId: 'user-linh',
          fullName: 'Hoang Linh',
          avatarUrl: linhPhoto,
        ),
        MatchMemberInfo(userId: 'user-duong', fullName: 'Quy Dương'),
      ],
    );
    final repository = _PagedMatchRepository({
      null: (matches: [match], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Quy Dương / Hoang Linh'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CircleAvatar &&
            widget.backgroundImage is NetworkImage &&
            (widget.backgroundImage as NetworkImage).url == linhPhoto,
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a guest pair shows one circle per athlete, not the team', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // Cặp VĐV chưa có tài khoản: tên đội là tên ghép hai VĐV nên chuẩn
    // hiển thị chọn chế độ VĐV — mỗi người một vòng tròn chữ cái đầu.
    final match = MatchModel(
      id: 'guest-match',
      tournamentId: _tournament.id,
      round: 1,
      matchNumber: 1,
      team1Id: 'p-guest',
      team2Id: 'p-other',
      team1Name: 'Nguyễn Minh Anh / Trần Quốc Bảo',
      team2Name: 'Biên Hòa Pickleball',
      status: 'scheduled',
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 10, 19),
      team1MemberInfos: MatchMemberInfo.guestsOf({
        'guestNames': ['Nguyễn Minh Anh', 'Trần Quốc Bảo'],
      }),
      team2MemberInfos: MatchMemberInfo.guestsOf({
        'guestNames': ['Võ Thành Đạt', 'Đặng Gia Khánh'],
      }),
    );
    final repository = _PagedMatchRepository({
      null: (matches: [match], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('N'), findsWidgets);
    expect(find.text('T'), findsWidgets);
    expect(find.text('Nguyễn Minh Anh / Trần Quốc Bảo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pair named "A / B" without members shows the full name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final match = _match(
      id: 'named-pair-match',
      team2Id: 'team-pair-id',
      team2Name: 'Phan Anh Khoa / Hồ Minh Trí',
    );
    final repository = _PagedMatchRepository({
      null: (matches: [match], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    // Không dựng VĐV giả từ tên đội: hiện nguyên tên đội hai người.
    expect(find.text('Phan Anh Khoa / Hồ Minh Trí'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-LIVECARD-01 live card puts the score below both names', (
    tester,
  ) async {
    _phone(tester);
    final match = _liveMatch();
    final repository = _PagedMatchRepository({
      null: (matches: [match], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository, MatchStatusFilter.live));
    await tester.pumpAndSettle();

    final score = tester.getRect(find.text('4 - 4'));
    final labels = find
        .byType(ParticipantLabel)
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)))
        .toList();
    expect(labels, hasLength(2));
    for (final label in labels) {
      // The score must not share a row with the names, and each name keeps
      // close to half of the 275 px card instead of ~88 px.
      expect(score.top, greaterThanOrEqualTo(label.bottom - 0.5));
      expect(label.width, greaterThan(110));
    }
    expect(tester.takeException(), isNull);
  });
}

Widget _cardApp(
  IMatchRepository repository, [
  MatchStatusFilter filter = MatchStatusFilter.scheduled,
]) {
  return ProviderScope(
    overrides: [matchRepositoryProvider.overrideWith((ref) => repository)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LiveTournamentWithMatchesCard(
            tournament: _tournament,
            filter: filter,
            initialPage: _firstPage(repository),
          ),
        ),
      ),
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// The feed hands the card its first page; here it is the repository's page
/// for the null cursor, already filtered the way the feed would.
FeedPage _firstPage(IMatchRepository repository) {
  final page = (repository as _PagedMatchRepository).pages[null]!;
  return FeedPage(
    FeedPageStatus.ready,
    items: page.matches,
    nextCursor: page.nextCursor,
  );
}

final _tournament = Tournament(
  id: 'synthetic-tournament',
  name: 'Synthetic tournament',
  sport: 'pickleball',
  format: 'single_elimination',
  bracketType: 'SINGLE_ELIMINATION',
  status: 'registration',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'synthetic-user',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  startDate: DateTime.utc(2026, 10, 1),
);

final _placeholderMatch = _match(
  id: 'placeholder-match',
  team2Id: 'team-tbd-id',
  team2Name: 'TBD',
);

final _visibleMatch = _match(
  id: 'visible-match',
  team2Id: 'team-beta-id',
  team2Name: 'Team Beta',
);

final _secondPageMatch = _match(
  id: 'second-page-match',
  team2Id: 'team-gamma-id',
  team2Name: 'Second Page Team',
);

MatchModel _liveMatch() {
  return MatchModel(
    id: 'live-match',
    tournamentId: _tournament.id,
    round: 1,
    matchNumber: 1,
    team1Id: 'team-lm-id',
    team2Id: 'team-ld-id',
    team1Name: 'Phan Anh Khoa / Hồ Minh Trí',
    team2Name: 'Nguyễn Văn Luân / Trần Quốc Dũng',
    status: 'live',
    court: 'Sân 1',
    scoreDetails: {
      'sets': [
        {'score1': 4, 'score2': 4, 'isFinished': false},
      ],
    },
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 9, 27),
  );
}

MatchModel _match({
  required String id,
  required String team2Id,
  required String team2Name,
}) {
  return MatchModel(
    id: id,
    tournamentId: _tournament.id,
    round: 1,
    matchNumber: 1,
    team1Id: 'team-alpha-id',
    team2Id: team2Id,
    team1Name: 'Team Alpha',
    team2Name: team2Name,
    status: 'scheduled',
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 9, 27),
  );
}

class _PagedMatchRepository extends Fake implements IMatchRepository {
  _PagedMatchRepository(this.pages);

  final Map<String?, _Page> pages;
  final List<String?> requests = [];
  Completer<void>? gate;
  var failOnce = false;

  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getTournamentMatchesPaged({
    required String tournamentId,
    String? status,
    String? cursor,
    int limit = 4,
    String? trigger,
  }) async {
    requests.add(cursor);
    await gate?.future;
    if (failOnce) {
      failOnce = false;
      throw StateError('boom');
    }
    final page = pages[cursor]!;
    return (
      matches: page.matches,
      nextCursor: page.nextCursor,
      hasMore: page.nextCursor != null,
      total: page.matches.length,
    );
  }
}
