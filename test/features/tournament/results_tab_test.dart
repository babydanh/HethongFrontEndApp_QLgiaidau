import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'results-test';
const _divisionId = 'doubles';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _completedTournament() => Tournament(
  id: _tournamentId,
  name: 'Results test',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'completed',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'fixture-owner',
  maxTeams: 16,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  divisions: const [
    TournamentDivision(
      id: 'singles',
      name: 'Đơn Nam',
      matchType: 'SINGLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
    ),
    TournamentDivision(
      id: _divisionId,
      name: 'Đôi Nam',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
    ),
  ],
);

void main() {
  testWidgets('thẻ giải hiện tên đội, hai thành viên và avatar', (
    tester,
  ) async {
    await _pumpResults(tester, _resultWithAward());

    expect(find.text('CLB Sài Gòn'), findsOneWidget);
    expect(find.text('Nguyễn Minh · Trần Quốc'), findsOneWidget);
    expect(find.text('QUÁN QUÂN'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    final images = find.byType(Image);
    expect(images, findsNWidgets(2));
    final imageUrls = tester
        .widgetList<Image>(images)
        .map((image) => (image.image as NetworkImage).url)
        .toSet();
    expect(imageUrls, {
      'https://example.invalid/minh.png',
      'https://example.invalid/quoc.png',
    });
    expect(find.text('N'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
  });

  testWidgets('avatar thiếu URL dùng chữ cái đầu của từng thành viên', (
    tester,
  ) async {
    await _pumpResults(tester, _resultWithAward(includeAvatarUrls: false));

    final results = find.byType(ResultsTab);
    expect(
      find.descendant(of: results, matching: find.text('N')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: results, matching: find.text('T')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: results, matching: find.byType(Image)),
      findsNothing,
    );
  });

  testWidgets('hạng mục SINGLES chỉ hiện một người và avatar', (tester) async {
    await _pumpIntro(tester);
    await tester.tap(find.widgetWithText(Tab, 'Kết quả'));
    await tester.pumpAndSettle();

    final results = find.byType(ResultsTab);
    expect(find.text('CLB Sài Gòn'), findsOneWidget);
    expect(find.text('Nguyễn Minh'), findsOneWidget);
    expect(find.text('Trần Quốc'), findsNothing);
    expect(
      find.descendant(of: results, matching: find.byType(ClipOval)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: results, matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('hạng mục DOUBLES hiện đủ hai người và avatar', (tester) async {
    await _pumpIntro(tester);
    await tester.tap(find.widgetWithText(Tab, 'Kết quả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đôi Nam'));
    await tester.pumpAndSettle();

    final results = find.byType(ResultsTab);
    expect(find.text('Nguyễn Minh · Trần Quốc'), findsOneWidget);
    expect(
      find.descendant(of: results, matching: find.byType(ClipOval)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: results, matching: find.byType(Image)),
      findsNWidgets(2),
    );
  });

  testWidgets('hạng mục rỗng không hiện bục hoặc thẻ thứ hạng', (tester) async {
    await _pumpResults(tester, {'awards': <dynamic>[]});

    expect(find.text('Chưa có kết quả chính thức'), findsOneWidget);
    expect(find.text('DANH SÁCH TRAO THƯỞNG'), findsNothing);
    expect(find.text('CLB Sài Gòn'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });
}

Future<void> _pumpResults(
  WidgetTester tester,
  Map<String, dynamic> result,
) async {
  _phone(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentResultProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith((ref) => Stream.value(result)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ResultsTab(
            tournamentId: _tournamentId,
            selectedDivisionId: _divisionId,
            selectedDivision: 'Đôi Nam',
            matchType: 'DOUBLES',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpIntro(WidgetTester tester) async {
  _phone(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentIntroWithInviteProvider.overrideWith(
          (ref, params) async => _completedTournament(),
        ),
        tournamentDivisionsProvider.overrideWith((ref, id) async => const []),
        introTeamsProvider.overrideWith((ref, id) async => const <Team>[]),
        followedTournamentsProvider.overrideWith((ref) async => const []),
        matchesProvider.overrideWith((ref, id) => Stream.value(const [])),
        bracketMatchesProvider.overrideWith(
          (ref, id) => Stream.value(const []),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
        tournamentResultProvider.overrideWith(
          (ref, params) => Stream.value(_resultWithAward()),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: '', fullName: 'Guest'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const TournamentIntroScreen(tournamentId: _tournamentId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Map<String, dynamic> _resultWithAward({bool includeAvatarUrls = true}) => {
  'awards': [
    {
      'rank': 1,
      'participant': {
        'teamName': 'CLB Sài Gòn',
        'members': [
          {
            'fullName': 'Nguyễn Minh',
            if (includeAvatarUrls)
              'avatarUrl': 'https://example.invalid/minh.png',
          },
          {
            'fullName': 'Trần Quốc',
            if (includeAvatarUrls)
              'avatarUrl': 'https://example.invalid/quoc.png',
          },
        ],
      },
    },
  ],
};
