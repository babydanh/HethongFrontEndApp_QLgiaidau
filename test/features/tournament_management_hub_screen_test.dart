import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/mock_participants_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_date_time_picker_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_brands_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/participant_detail_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_dispatcher.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_report_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/wildcard_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Tournament _tournament(
  String status, {
  String name = 'City Pickleball Cup',
  String sport = 'pickleball',
  bool superLite = false,
  bool quick = false,
  String? communityId,
  String? bannerUrl,
  String? logoUrl,
  String description = '',
  DateTime? startDate,
  DateTime? registrationEndDate,
  Map<String, dynamic>? contactInfo,
  List<Map<String, dynamic>> divisions = const [],
}) => Tournament.fromJson({
  'name': name,
  'sport': sport,
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'description': description,
  if (quick) 'isLite': true,
  'communityId': communityId,
  'bannerUrl': bannerUrl,
  'logoUrl': logoUrl,
  if (superLite)
    'tournamentConfig': {'mode': 'LITE', 'hideAdvancedSettings': true},
  if (startDate != null) 'startDate': startDate.toIso8601String(),
  if (registrationEndDate != null)
    'registrationEndDate': registrationEndDate.toIso8601String(),
  'contactInfo': ?contactInfo,
  if (divisions.isNotEmpty) 'divisions': divisions,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Widget _app(
  Tournament tournament, {
  Locale locale = const Locale('vi'),
  UserProfile? profile,
  TournamentManagementRepository? managementRepository,
  ITournamentRepository? tournamentRepository,
  List<MatchModel>? matches,
}) => ProviderScope(
  overrides: [
    userProfileProvider.overrideWith(
      (ref) async =>
          profile ??
          const UserProfile(
            id: 'manager-1',
            role: 'ORGANIZER',
            roles: ['ORGANIZER', 'ADMIN'],
          ),
    ),
    if (managementRepository != null)
      tournamentManagementRepositoryProvider.overrideWithValue(
        managementRepository,
      ),
    if (tournamentRepository != null)
      tournamentRepositoryProvider.overrideWithValue(tournamentRepository),
    if (matches != null)
      matchesProvider(
        'tournament-1',
      ).overrideWith((ref) => Stream.value(matches)),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: TournamentManagementHubScreen(
      tournament: tournament,
      actionRouteBase: '/admin/tournament/tournament-1',
      opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
      liteWorkspaceRoute: '/lite-manage/tournament-1?workspace=1',
    ),
  ),
);

class _AuthenticatedAdmin extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.admin);
}

class _EmptyRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => [];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async => [];

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) async =>
      [];
}

class _EmptyTournamentRepository implements ITournamentRepository {
  @override
  Future<Map<String, dynamic>> generateBracket(
    String tournamentId, {
    String? divisionId,
    required String seedingType,
    bool allowReset = false,
  }) => throw UnimplementedError();
  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every tournament update the popups send.
class _UpdateRecorder extends _EmptyTournamentRepository {
  final updates = <Map<String, dynamic>>[];

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    updates.add(data);
  }
}

class _PatchRecorder extends _EmptyTournamentManagementRepository
    implements TournamentSettingsRepository {
  final patches = <Map<String, dynamic>>[];

  @override
  Future<void> updateTournament(String id, Map<String, dynamic> payload) async {
    patches.add(payload);
  }
}

class _OneVenueRepository extends _EmptyTournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'North Hall',
      'locationAddress': '12 Lake Road',
      'isDefault': true,
      'courts': const [],
    },
  ];
}

class _DivisionParticipantsRepository implements ITournamentRepository {
  @override
  Future<Map<String, dynamic>> generateBracket(
    String tournamentId, {
    String? divisionId,
    required String seedingType,
    bool allowReset = false,
  }) => throw UnimplementedError();
  _DivisionParticipantsRepository(this.participants);

  final List<OrganizerOpsParticipant> participants;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => divisionId == null
      ? participants
      : participants.where((p) => p.divisionId == divisionId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyTournamentManagementRepository
    implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];

  @override
  Future<Map<String, dynamic>> getFeesConfig() async => const {};

  @override
  Future<List<Map<String, dynamic>>> getMyPayouts() async => const [];

  @override
  Future<List<String>> getGallery(String id) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LifecycleRepository extends _EmptyTournamentManagementRepository
    implements TournamentLifecycleRepository {
  final startedIds = <String>[];
  final completedIds = <String>[];
  final calls = <String>[];
  Object? completeError;

  /// Không hạng mục nào mở đăng ký: card khai mạc giữ hộp thoại xác nhận cũ.
  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      const [];

  @override
  Future<Map<String, dynamic>> startTournament(String id) async {
    startedIds.add(id);
    calls.add('start');
    return const {};
  }

  @override
  Future<Map<String, dynamic>> closeRegistration(String id) async {
    calls.add('close-registration');
    return const {};
  }

  @override
  Future<Map<String, dynamic>> reopenRegistration(
    String id, {
    DateTime? registrationEndDate,
    List<String>? divisionIds,
  }) async {
    calls.add('reopen-registration');
    return const {};
  }

  @override
  Future<Map<String, dynamic>> completeTournament(String id) async {
    completedIds.add(id);
    if (completeError != null) throw completeError!;
    return const {};
  }
}

class _RecordingManagementRepository
    extends _EmptyTournamentManagementRepository {
  final directNames = <String>[];
  final statusUpdates = <Map<String, String>>[];
  final seededMockNames = <List<String>>[];
  final reservedSlotContacts = <String>[];

  @override
  Future<String> addAthleteDirect(
    String id, {
    required String name,
    String? email,
    String? phone,
    String? notes,
    double? elo,
    String? eloSource,
    String? tournamentDivisionId,
  }) async {
    directNames.add(name);
    return 'participant-direct';
  }

  @override
  Future<void> updateParticipantStatus(
    String id,
    String participantId,
    String status,
  ) async {
    statusUpdates.add({'participantId': participantId, 'status': status});
  }

  @override
  Future<void> seedMockParticipants(
    String id,
    List<String> names, {
    String? divisionId,
    String? pairingMode,
  }) async {
    seededMockNames.add(names);
  }

  @override
  Future<void> reserveSlots(
    String id, {
    required String userEmailOrPhone,
    required String teamName,
    String? partnerEmailOrPhone,
    String? divisionId,
  }) async {
    reservedSlotContacts.add(userEmailOrPhone);
  }
}

class _IdleLiteManagementNotifier extends LiteManagementNotifier {
  @override
  Future<void> init(String tournamentId) async {}
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  final context = tester.element(find.byType(TournamentManagementHubScreen));
  final l10n = AppLocalizations.of(context)!;
  await _openTab(tester, l10n.tournamentManagementTabSettings);
}

void main() {
  testWidgets('overview tournament title opens the name popup', (tester) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('City Pickleball Cup'));
    await tester.pumpAndSettle();

    final popup = find.byType(BottomSheet);
    expect(popup, findsOneWidget);
    expect(
      find.descendant(
        of: popup,
        matching: find.widgetWithText(TextField, 'City Pickleball Cup'),
      ),
      findsOneWidget,
    );
  });
  testWidgets('overview edit targets open their own popup, not a page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;

    for (final key in [
      'tournament-overview-banner-edit',
      'tournament-overview-location-edit',
      'tournament-overview-entry-fee-edit',
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _app(
          _tournament(
            'in_progress',
            description: 'Cup overview description',
            startDate: DateTime(2030, 1, 1),
          ),
          managementRepository: _EmptyTournamentManagementRepository(),
          tournamentRepository: _EmptyTournamentRepository(),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.byKey(ValueKey(key));
      expect(target, findsOneWidget, reason: key);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget, reason: key);
    }
  });

  group('TC-EDIT: tapping an item opens a popup for exactly that item', () {
    Future<void> pumpHub(
      WidgetTester tester,
      Tournament tournament, {
      ITournamentRepository? tournamentRepository,
      TournamentManagementRepository? managementRepository,
    }) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          tournament,
          managementRepository:
              managementRepository ?? _EmptyTournamentManagementRepository(),
          tournamentRepository:
              tournamentRepository ?? _EmptyTournamentRepository(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapKey(WidgetTester tester, String key) async {
      final target = find.byKey(ValueKey(key));
      expect(target, findsOneWidget, reason: key);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Finder inPopup(Finder finder) =>
        find.descendant(of: find.byType(BottomSheet), matching: finder);

    bool focused(WidgetTester tester, Finder textField) => tester
        .widget<EditableText>(
          find.descendant(of: textField, matching: find.byType(EditableText)),
        )
        .focusNode
        .hasFocus;

    testWidgets('name: a popup with only the name field, saved on its own', (
      tester,
    ) async {
      final repo = _UpdateRecorder();
      await pumpHub(tester, _tournament('registration'), tournamentRepository: repo);
      await tapKey(tester, 'tournament-overview-name-edit');

      expect(find.byType(BottomSheet), findsOneWidget);
      final fields = inPopup(find.byType(TextField));
      expect(fields, findsOneWidget, reason: 'only the name, nothing else');
      expect(focused(tester, fields), isTrue);

      await tester.enterText(fields, 'New cup name');
      await tester.pump();
      await tester.tap(inPopup(find.byType(FilledButton)));
      await tester.pumpAndSettle();

      expect(repo.updates.single['name'], 'New cup name');
      expect(find.byType(BottomSheet), findsNothing, reason: 'closes after save');
    });

    testWidgets('banner and logo: the logo and banner picker in a popup', (
      tester,
    ) async {
      await pumpHub(tester, _tournament('registration'));
      await tapKey(tester, 'tournament-overview-banner-edit');

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        inPopup(find.byType(TournamentManagementBrandsSection)),
        findsOneWidget,
      );
    });

    testWidgets('contact: phone and email in a popup, saved on their own', (
      tester,
    ) async {
      final repo = _UpdateRecorder();
      await pumpHub(
        tester,
        _tournament(
          'registration',
          contactInfo: {'phone': '0900000001', 'email': 'a@example.test'},
        ),
        tournamentRepository: repo,
      );
      await tapKey(tester, 'tournament-overview-contact-edit');

      expect(find.byType(BottomSheet), findsOneWidget);
      final phone = inPopup(find.byKey(const ValueKey('info-contact-phone')));
      expect(phone, findsOneWidget);
      // Same fields as the Web tab: source, phone, email and the add-link form.
      expect(inPopup(find.byKey(const ValueKey('info-contact-mode'))), findsOneWidget);
      expect(inPopup(find.byKey(const ValueKey('info-contact-email'))), findsOneWidget);
      expect(inPopup(find.byKey(const ValueKey('info-contact-link-value'))), findsOneWidget);

      await tester.enterText(phone, '0900000002');
      await tester.pump();
      await tester.tap(inPopup(find.byType(FilledButton)));
      await tester.pumpAndSettle();

      final contact = repo.updates.single['contactInfo'] as Map;
      expect(contact['phone'], '0900000002');
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('venue: the venue editor is open inside the popup', (
      tester,
    ) async {
      await pumpHub(
        tester,
        _tournament('registration'),
        managementRepository: _OneVenueRepository(),
      );
      await tapKey(tester, 'tournament-overview-location-edit');

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.widgetWithText(TextField, 'North Hall'), findsOneWidget);
    });

    testWidgets('fee: a popup with the fee field focused, saved on its own', (
      tester,
    ) async {
      final repo = _UpdateRecorder();
      await pumpHub(tester, _tournament('registration'), tournamentRepository: repo);
      await tapKey(tester, 'tournament-overview-entry-fee-edit');

      expect(find.byType(BottomSheet), findsOneWidget);
      final fee = inPopup(find.byType(TextField));
      expect(fee, findsOneWidget);
      expect(focused(tester, fee), isTrue);

      await tester.enterText(fee, '50000');
      await tester.pump();
      await tester.tap(inPopup(find.byType(LavishButton)).last);
      await tester.pumpAndSettle();

      expect(repo.updates.single, {'entryFee': 50000});
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('each roadmap row opens a popup with its own date picker', (
      tester,
    ) async {
      final tournament = _tournament(
        'registration',
        startDate: DateTime(2030, 1, 1),
        registrationEndDate: DateTime(2029, 12, 1),
      );
      for (final key in [
        'tournament-overview-timeline-opens-edit',
        'tournament-overview-timeline-deadline-edit',
        'tournament-overview-timeline-opening-edit',
        'tournament-overview-timeline-closing-edit',
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpHub(tester, tournament);
        await tapKey(tester, key);
        // Only the date picker: no form sheet around it.
        expect(find.byType(BottomSheet), findsOneWidget, reason: key);
        expect(
          find.byType(SocialDateTimePickerSheet),
          findsOneWidget,
          reason: key,
        );
      }
    });

    testWidgets('TC-EYE-01: the founder eye on a MANUAL tournament shows the founder again', (
      tester,
    ) async {
      final repo = _PatchRecorder();
      final tournament = Tournament.fromJson({
        'name': 'Eye regression',
        'sport': 'pickleball',
        'format': 'doubles',
        'bracketType': 'single_elimination',
        'status': 'registration',
        'creator': {'id': 'creator-1', 'fullName': 'Organizer Name'},
        'contactInfo': {
          'displayMode': 'MANUAL',
          'organizerName': 'Ban to chuc A',
          'hidden': true,
        },
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'tournament-1');
      await pumpHub(tester, tournament, managementRepository: repo);

      await tapKey(tester, 'tournament-founder-eye');

      final contactInfo =
          repo.patches.single['contactInfo'] as Map<String, dynamic>;
      expect(contactInfo['hidden'], false);
      expect(contactInfo['displayMode'], 'PROFILE');
      expect(contactInfo['organizerName'], 'Ban to chuc A');
    });

    testWidgets('TC-EYE-02: the banner eye hides the card text and saves it', (
      tester,
    ) async {
      final repo = _PatchRecorder();
      await pumpHub(
        tester,
        _tournament('registration', bannerUrl: 'https://example.test/b.png'),
        managementRepository: repo,
      );

      await tester.tap(
        find.byKey(const ValueKey('tournament-banner-card-text-eye')),
      );
      await tester.pumpAndSettle();

      final config =
          repo.patches.single['tournamentConfig'] as Map<String, dynamic>;
      expect(config['hideFeaturedCardText'], true);
    });

    testWidgets('closing the date picker without a choice closes the popup', (
      tester,
    ) async {
      await pumpHub(
        tester,
        _tournament(
          'registration',
          startDate: DateTime(2030, 1, 1),
          registrationEndDate: DateTime(2029, 12, 1),
        ),
      );
      await tapKey(tester, 'tournament-overview-timeline-deadline-edit');
      Navigator.of(tester.element(find.byType(SocialDateTimePickerSheet))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(SocialDateTimePickerSheet), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  testWidgets(
    'TC-FEAT-HDR-01: header has a 4-step progress bar, no KPI strip',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_app(_tournament('in_progress')));
      await tester.pumpAndSettle();

      // The current step is lit and the Web's 4 steps are all shown.
      expect(
        find.byKey(const ValueKey('lifecycle-step-current')),
        findsOneWidget,
      );
      for (final label in [
        'Đăng ký',
        'Lịch thi đấu',
        'Đang thi đấu',
        'Kết thúc',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      // The old 4-cell strip (dates, athletes, deadline) is gone from the top.
      for (final key in [
        'tournament-overview-dates-edit',
        'tournament-overview-athletes-edit',
        'tournament-management-kpi-deadline',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
      }
      // The tournament logo sits on the banner.
      expect(
        find.byKey(const ValueKey('tournament-overview-logo')),
        findsOneWidget,
      );
      // No drop shadow on the logo: it hangs at the edge of the banner box,
      // where a shadow is cut off into a hard horizontal line.
      final logoShadows = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(const ValueKey('tournament-overview-logo')),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .expand((decoration) => decoration.boxShadow ?? const <BoxShadow>[]);
      expect(logoShadows, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hub shows five pinned tabs and grouped settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(_tournament('in_progress'), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementHubScreen)),
    )!;
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('City Pickleball Cup'), findsOneWidget);
    for (final label in [
      l10n.tournamentManagementOverview,
      l10n.tournamentManagementTabAthletes,
      l10n.tournamentManagementTabBracket,
      l10n.tournamentManagementSchedule,
      l10n.tournamentManagementTabSettings,
    ]) {
      expect(find.widgetWithText(Tab, label), findsOneWidget);
    }

    await _openSettings(tester);
    expect(find.text(l10n.tournamentManagementSetupGroup), findsOneWidget);
    expect(find.text(l10n.manageSettingsInfoSection), findsOneWidget);
    expect(find.text(l10n.tournamentManagementSystemGroup), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket and schedule tabs render embedded workspaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
          bracketMatchesWithDivisionProvider((
            tournamentId: 'tournament-1',
            divisionId: null,
          )).overrideWith((ref) => Stream.value(const <MatchModel>[])),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: _app(_tournament('in_progress'), locale: const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementHubScreen)),
    )!;
    await _openTab(tester, l10n.tournamentManagementTabBracket);
    expect(find.text(l10n.bracketView_noMatches), findsOneWidget);
    expect(find.text(l10n.bracketView_drawHint), findsOneWidget);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);

    await _openTab(tester, l10n.tournamentManagementSchedule);
    expect(find.byType(OrganizerOpsScreen), findsOneWidget);
    // The schedule tab starts right under the tab strip: no refresh row there.
    expect(find.byTooltip(l10n.opsRefresh), findsNothing);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin, organizer, and Lite entry routes share one hub', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'admin-1', role: 'ADMIN', roles: ['ADMIN']),
        ),
        authProvider.overrideWith(_AuthenticatedAdmin.new),
        tournamentProvider('tournament-1').overrideWith(
          (ref) => Stream.value(_tournament('in_progress', quick: true)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/admin/tournament/tournament-1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);

    for (final location in [
      '/organizer/tournaments/tournament-1/manage',
      '/lite-manage/tournament-1',
      '/lite/tournaments/tournament-1/manage',
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    }
    for (final location in [
      '/lite-manage/tournament-1?workspace=1',
      '/lite/tournaments/tournament-1/manage?workspace=1',
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(LiteManagementScreen), findsNothing);
      expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    }
  });

  testWidgets('club Super Lite keeps the existing Lite management screen', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_AuthenticatedAdmin.new),
        tournamentProvider('tournament-1').overrideWith(
          (ref) => Stream.value(
            _tournament('in_progress', superLite: true, communityId: 'club-1'),
          ),
        ),
        regionRepositoryProvider.overrideWith(
          (ref) => _EmptyRegionRepository(),
        ),
        liteManagementProvider.overrideWith(_IdleLiteManagementNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/lite-manage/tournament-1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LiteManagementScreen), findsOneWidget);
    expect(find.byType(TournamentManagementHubScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Advanced organizer entry opens the shared hub', (tester) async {
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'admin-1', role: 'ADMIN', roles: ['ADMIN']),
        ),
        authProvider.overrideWith(_AuthenticatedAdmin.new),
        tournamentProvider(
          'tournament-1',
        ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/organizer/tournaments/tournament-1/manage');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
  });
  testWidgets('cancel preserves the tournament; success refreshes its status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    var tournamentReads = 0;
    final lifecycleRepository = _LifecycleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'admin-1',
              role: 'ADMIN',
              roles: ['ADMIN'],
            ),
          ),
          tournamentProvider('tournament-1').overrideWith((ref) {
            tournamentReads += 1;
            return Stream.value(
              _tournament(tournamentReads == 1 ? 'in_progress' : 'completed'),
            );
          }),
          tournamentManagementRepositoryProvider.overrideWithValue(
            lifecycleRepository,
          ),
          // Sheet kết thúc đếm trận từ matchesProvider: mọi trận đã xong, không
          // còn trận LIVE nên nút kết thúc bật được.
          matchesProvider(
            'tournament-1',
          ).overrideWith((ref) => Stream.value(<MatchModel>[])),
          // The completed tournament reads the results snapshot (reconfirm card).
          tournamentResultProvider((
            tournamentId: 'tournament-1',
            divisionId: null,
          )).overrideWith((ref) => Stream.value(const {'awards': []})),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const TournamentManagementDispatcher(
            tournamentId: 'tournament-1',
            actionRouteBase: '/admin/tournament/tournament-1',
            opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.endTournament));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('tournament-manage-sheet-close')),
    );
    await tester.pumpAndSettle();
    expect(lifecycleRepository.completedIds, isEmpty);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsOneWidget);

    await tester.tap(find.text(l10n.endTournament));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lifecycle-end-confirm')));
    await tester.pumpAndSettle();
    // The confirm button first asks for confirmation (states the consequence).
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.lifecycleEndConfirm),
      ),
    );
    await tester.pumpAndSettle();

    expect(lifecycleRepository.completedIds, ['tournament-1']);
    expect(tournamentReads, 2);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsNothing);
    expect(find.text(l10n.tournamentEnded), findsOneWidget);
  });

  testWidgets('organizer sees the end action; permission stays server-side', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        profile: const UserProfile(
          id: 'organizer-1',
          role: 'ORGANIZER',
          roles: ['ORGANIZER'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    // Change quan-ly-giai-web-parity: organizer/co-organizer cũng kết thúc
    // được — backend chốt quyền (403 hiện nguyên văn trong sheet).
    expect(find.text(l10n.endTournament), findsOneWidget);
  });

  testWidgets('keeps lite management accessible from overflow actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    final tournament = _tournament('in_progress', superLite: true);
    final router = GoRouter(
      initialLocation: '/organizer/tournaments/tournament-1/manage',
      routes: [
        GoRoute(
          path: '/organizer/tournaments/:id/manage',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TournamentManagementHubScreen(
              tournament: tournament,
              actionRouteBase: '/organizer/tournaments/$id/manage',
              opsWorkspaceRoute: '/organizer/tournaments/$id/ops',
              liteWorkspaceRoute: '/lite-manage/$id?workspace=1',
            );
          },
        ),
        GoRoute(
          path: '/lite-manage/:id',
          builder: (context, state) =>
              const Scaffold(body: Text('Destination: lite')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.lite_managementTitle));
    await tester.pumpAndSettle();

    expect(find.text('Destination: lite'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('settings retain every management section and action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);

    expect(find.text(l10n.tournamentManagementSetupGroup), findsOneWidget);
    expect(find.text(l10n.manageSettingsInfoSection), findsOneWidget);
    expect(find.text(l10n.manageSettingsVenueSection), findsOneWidget);
    expect(find.text(l10n.tournamentManagementRegistration), findsOneWidget);
    // Divisions moved to their own tab; settings no longer list them.
    expect(find.text(l10n.manageSettingsCompetitionSection), findsNothing);

    // Nhóm Hệ thống luôn mở: các mục nằm sẵn trong danh sách.
    expect(find.text(l10n.tournamentManagementSystemGroup), findsOneWidget);
    expect(find.text(l10n.manageTeams), findsOneWidget);
    expect(find.text(l10n.manageDraw), findsOneWidget);
    expect(find.text(l10n.tournamentManagementSponsors), findsOneWidget);
    expect(find.text(l10n.tournamentManagementFinance), findsOneWidget);
    expect(find.text(l10n.tournamentManagementLivestream), findsOneWidget);
    expect(find.text(l10n.tournamentManagementPermissions), findsOneWidget);
    expect(find.text(l10n.manageTokens), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsOneWidget);
    expect(find.text(l10n.exportData), findsOneWidget);
    expect(find.text(l10n.exportParticipantsRoster), findsOneWidget);
    expect(find.text(l10n.deleteTournament), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('export menu lists both export actions (task 3.9)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Kết quả và danh sách VĐV là hai mục xuất riêng, cùng bị chặn khi đang export.
    expect(find.text(l10n.exportData), findsOneWidget);
    expect(find.text(l10n.exportParticipantsRoster), findsOneWidget);
    expect(
      find.widgetWithText(PopupMenuItem<String>, l10n.exportParticipantsRoster),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('overflow menu opens the report sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentReportMenu));
    await tester.pumpAndSettle();

    expect(find.byType(TournamentReportSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('management overview shows one title and the provided banner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    const bannerUrl = 'https://images.example/tournament-banner.jpg';

    await tester.pumpWidget(
      _app(_tournament('in_progress', bannerUrl: bannerUrl)),
    );

    expect(find.text('City Pickleball Cup'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url == bannerUrl,
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides finalization action for a completed tournament', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('completed')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text(l10n.endTournament), findsNothing);
    expect(find.text(l10n.exportData), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await _openSettings(tester);
    expect(find.text(l10n.manageSettingsInfoSection), findsOneWidget);
  });
  testWidgets('supports long English tournament names on phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament(
          'completed',
          name: 'International Community Pickleball Doubles Championship',
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'phone navigation opens the information editor with brand assets',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openSettings(tester);
      await tester.tap(find.text(l10n.manageSettingsInfoSection).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.tournamentManagementName), findsOneWidget);
      expect(find.text(l10n.tournamentManagementDescription), findsOneWidget);
      for (final group in [
        l10n.manageInfoGroupGeneral,
        l10n.manageInfoGroupIdentity,
        l10n.manageInfoGroupPrizes,
        l10n.manageInfoGroupContact,
      ]) {
        expect(find.text(group.toUpperCase()), findsOneWidget);
      }
      // Branding is collapsed by default; opening it reveals the image tiles.
      await tester.tap(find.text(l10n.manageInfoGroupIdentity.toUpperCase()));
      await tester.pumpAndSettle();
      expect(find.text(l10n.tournamentManagementLogo), findsOneWidget);
      expect(find.text(l10n.tournamentManagementChooseDate), findsNothing);
      expect(find.text(l10n.tournamentManagementPublic), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'venue editor shows venues only, without dates or registration fields',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openSettings(tester);
      await tester.tap(find.text(l10n.manageSettingsVenueSection).first);
      await tester.pumpAndSettle();

      // The venues page has no card title any more: the add button leads it.
      expect(find.text(l10n.tournamentManagementAddVenue), findsOneWidget);
      expect(find.text(l10n.tournamentManagementStartDate), findsNothing);
      expect(find.text(l10n.tournamentManagementEndDate), findsNothing);
      expect(find.text(l10n.tournamentManagementChooseDate), findsNothing);
      expect(find.text(l10n.tournamentManagementPublic), findsNothing);
      expect(
        find.text(l10n.tournamentManagementRegistrationStarts),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pinned tab strip never covers the first settings group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await _openSettings(tester);

    final tabStripBottom = tester.getRect(find.byType(TabBar).first).bottom;
    final groupTop = tester
        .getRect(find.text(l10n.tournamentManagementSetupGroup).first)
        .top;
    expect(groupTop, greaterThanOrEqualTo(tabStripBottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stream updates preserve open section editor state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    final tournaments = StreamController<Tournament?>();
    addTearDown(tournaments.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => tournaments.stream),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _EmptyTournamentManagementRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const TournamentManagementDispatcher(
            tournamentId: 'tournament-1',
            actionRouteBase: '/organizer/tournaments/tournament-1/manage',
            opsWorkspaceRoute: '/organizer/tournaments/tournament-1/ops',
          ),
        ),
      ),
    );
    tournaments.add(_tournament('in_progress'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.manageSettingsInfoSection).first);
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    nameField.controller!.text = 'Unsaved tournament name';
    await tester.pump();
    tournaments.add(_tournament('in_progress', name: 'Server snapshot update'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Unsaved tournament name',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khác opens a destination and returns to the settings list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.tournamentManagementFinance));
    await tester.pumpAndSettle();
    final financeTitleInAppBar = find.descendant(
      of: find.byType(AppBar),
      matching: find.text(l10n.tournamentManagementFinance),
    );
    expect(financeTitleInAppBar, findsOneWidget);

    await tester.tap(find.byTooltip(l10n.tournamentManagementBack));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementSystemGroup), findsOneWidget);
    expect(financeTitleInAppBar, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('operations retains live operations and the final section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          introTeamsProvider(
            'tournament-1',
          ).overrideWith((ref) async => const []),
          tournamentRepositoryProvider.overrideWithValue(
            _EmptyTournamentRepository(),
          ),
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    final liveOperations = find.text(l10n.tournamentManagementLiveOperations);
    await tester.ensureVisible(liveOperations);
    await tester.tap(liveOperations);
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.opsRefresh), findsOneWidget);
    expect(find.byTooltip(l10n.tournamentManagementBack), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.tournamentManagementBack));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.tournamentManagementLivestream, skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet navigation updates the management detail section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.tournamentManagementRegistration).first);
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.tournamentManagementRegistrationMode),
      findsOneWidget,
    );
    expect(find.text(l10n.tournamentManagementPublic), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lifecycle bar and action lead the page, settings keep Other', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('draft')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    // The next-step button is at the top of the page; opening the settings
    // tab scrolls the header out of view, so it is checked first.
    expect(find.text(l10n.tournamentManagementPublish), findsOneWidget);
    await _openSettings(tester);

    // The step bar and the next-step button live in the header, once: the
    // settings tab only carries the "Other" group (share / delete).
    expect(
      find.byKey(const ValueKey('lifecycle-step-current')),
      findsNothing, // draft: no step lit
    );
    expect(find.byKey(const ValueKey('lifecycle-share')), findsOneWidget);
    expect(find.text(l10n.tournamentManagementRegenerateInvite), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'TC-APP-LIFECYCLE-04: lifecycle actions follow status and repository',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final startRepository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(_tournament('UPCOMING'), managementRepository: startRepository),
      );
      await tester.pumpAndSettle();

      final startContext = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final startL10n = AppLocalizations.of(startContext)!;
      // Sắp diễn ra: nút duy nhất là mở đăng ký.
      expect(
        find.text(startL10n.tournamentManagementOpenRegistrationNow),
        findsOneWidget,
      );
      expect(
        find.text(startL10n.tournamentManagementStartTournament),
        findsNothing,
      );

      await tester.pumpWidget(
        _app(
          _tournament('REGISTRATION_CLOSED'),
          managementRepository: startRepository,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(startL10n.tournamentManagementCompleteTournament),
        findsNothing,
      );
      // Đã đóng hết: khai mạc là nút chính, kèm lối "Mở lại đăng ký".
      expect(
        find.text(startL10n.tournamentManagementReopenRegistration),
        findsOneWidget,
      );
      await tester.tap(
        find.text(startL10n.tournamentManagementStartTournament),
      );
      await tester.pumpAndSettle();
      expect(
        startL10n.tournamentManagementStartTournamentConfirm,
        contains('Khai mạc sẽ khoá đăng ký tất cả nội dung.'),
      );
      expect(
        find.text(startL10n.tournamentManagementStartTournamentConfirm),
        findsOneWidget,
      );
      // Nút xác nhận tắt tới khi tick "Đóng đăng ký tất cả nội dung".
      final confirmFinder = find.widgetWithText(
        FilledButton,
        startL10n.tournamentManagementConfirm,
      );
      expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNull);
      await tester.tap(find.text(startL10n.tournamentManagementStartCloseAll));
      await tester.pumpAndSettle();
      await tester.tap(confirmFinder);
      await tester.pumpAndSettle();
      expect(startRepository.startedIds, ['tournament-1']);
      expect(startRepository.calls, ['start']);

      final completeRepository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(
          _tournament('IN_PROGRESS'),
          managementRepository: completeRepository,
        ),
      );
      await tester.pumpAndSettle();
      final completeContext = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final completeL10n = AppLocalizations.of(completeContext)!;
      expect(
        find.text(completeL10n.tournamentManagementCompleteTournament),
        findsOneWidget,
      );
      expect(
        find.text(completeL10n.tournamentManagementStartTournament),
        findsNothing,
      );
      await tester.tap(
        find.text(completeL10n.tournamentManagementCompleteTournament),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          completeL10n.tournamentManagementConfirm,
        ),
      );
      await tester.pumpAndSettle();
      expect(completeRepository.completedIds, ['tournament-1']);

      await tester.pumpWidget(
        _app(
          _tournament('COMPLETED'),
          managementRepository: _LifecycleRepository(),
        ),
      );
      await tester.pumpAndSettle();
      final completedL10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      expect(
        find.text(completedL10n.tournamentManagementStartTournament),
        findsNothing,
      );
      expect(
        find.text(completedL10n.tournamentManagementCompleteTournament),
        findsNothing,
      );
    },
  );
  testWidgets('TC-APP-LIFECYCLE-05: displays the server completion error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    const serverMessage = 'Còn trận đang diễn ra: Nội dung đôi';
    final request = RequestOptions(path: '/tournaments/tournament-1/complete');
    final repository = _LifecycleRepository()
      ..completeError = DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 400,
          data: const {'message': serverMessage},
        ),
      );
    await tester.pumpWidget(
      _app(_tournament('IN_PROGRESS'), managementRepository: repository),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.tournamentManagementCompleteTournament));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementConfirm),
    );
    await tester.pumpAndSettle();

    expect(find.text(serverMessage), findsOneWidget);
  });
  testWidgets(
    'TC-APP-LIFECYCLE-06: registration open without bracket closes registration, no lock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final repository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(
          _tournament('REGISTRATION_OPEN'),
          managementRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      expect(find.text(l10n.tournamentManagementStartTournament), findsNothing);
      await tester.tap(find.text(l10n.tournamentManagementCloseRegistration));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.tournamentManagementConfirm),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, ['close-registration']);
    },
  );
  testWidgets(
    'TC-APP-LIFECYCLE-07: bracket ready while registration remains open must close first',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final repository = _LifecycleRepository();
      final match = MatchModel(
        id: 'match-1',
        round: 1,
        matchNumber: 1,
        team1Name: 'A',
        team2Name: 'B',
        status: 'scheduled',
        bracketPosition: const BracketPosition(round: 1, position: 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        divisionId: 'div-1',
      );
      await tester.pumpWidget(
        _app(
          _tournament(
            'REGISTRATION_OPEN',
            divisions: [
              {'id': 'div-1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
            ],
          ),
          managementRepository: repository,
          matches: [match],
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      expect(
        find.text(l10n.tournamentManagementCloseRegistration),
        findsOneWidget,
      );
      expect(find.text(l10n.tournamentManagementStartTournament), findsNothing);
      await tester.tap(find.text(l10n.tournamentManagementCloseRegistration));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.tournamentManagementConfirm),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, ['close-registration']);
    },
  );
  testWidgets(
    'TC-APP-LIFECYCLE-08: reopening after the deadline passed asks for a new deadline first',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      final repository = _LifecycleRepository();
      await tester.pumpWidget(
        _app(
          _tournament(
            'REGISTRATION_CLOSED',
            registrationEndDate: DateTime.utc(2020, 1, 1),
          ),
          managementRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await tester.tap(find.text(l10n.tournamentManagementReopenRegistration));
      await tester.pumpAndSettle();

      // Server từ chối mở lại khi hạn cũ đã qua: phải chọn hạn mới trước.
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(repository.calls, isEmpty);
    },
  );

  testWidgets(
    'registration editor holds visibility, mode, dates and deadlines',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _app(
          _tournament('in_progress'),
          managementRepository: _EmptyTournamentManagementRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openSettings(tester);
      await tester.tap(find.text(l10n.tournamentManagementRegistration).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.tournamentManagementPublic), findsOneWidget);
      expect(
        find.text(l10n.tournamentManagementRegistrationMode),
        findsOneWidget,
      );
      expect(
        find.text(l10n.tournamentManagementRegistrationStarts),
        findsOneWidget,
      );
      expect(
        find.text(l10n.tournamentManagementRegistrationEnds),
        findsOneWidget,
      );
      expect(find.text(l10n.tournamentManagementStartDate), findsOneWidget);
      expect(find.text(l10n.tournamentManagementEndDate), findsOneWidget);
      expect(
        find.text(l10n.tournamentManagementRegenerateInvite),
        findsNothing,
      );
      expect(find.text(l10n.tournamentManagementName), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('banner collapses while tabs stay pinned', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    final title = find.text(l10n.managementTitle);
    double titleOpacity() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(of: title, matching: find.byType(AnimatedOpacity))
              .first,
        )
        .opacity;

    expect(titleOpacity(), 0);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(titleOpacity(), 1);
    expect(find.text('City Pickleball Cup').hitTestable(), findsNothing);
    expect(find.byType(TabBar).hitTestable(), findsOneWidget);
    expect(
      find.widgetWithText(Tab, l10n.tournamentManagementOverview).hitTestable(),
      findsOneWidget,
    );
    // Tab strip cuộn ngang ở 390 px, nên tab Cài đặt nằm ngoài viewport ban đầu.
    // Spec dòng 361 yêu cầu reachable: cuộn tab strip tới nó rồi mới kiểm hit-test.
    final settingsTab = find.widgetWithText(
      Tab,
      l10n.tournamentManagementTabSettings,
    );
    await tester.ensureVisible(settingsTab);
    await tester.pumpAndSettle();
    expect(settingsTab.hitTestable(), findsOneWidget);
  });

  testWidgets('athletes tab row with no registrations shows the empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    final divisions = <Map<String, dynamic>>[
      {'id': 'div-empty', 'name': 'Đôi Nam Nữ', 'matchType': 'DOUBLES'},
    ];
    final tournament = _tournament('in_progress', divisions: divisions);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          introTeamsProvider(
            'tournament-1',
          ).overrideWith((ref) async => const []),
          tournamentProvider(
            'tournament-1',
          ).overrideWith((ref) => Stream.value(tournament)),
          tournamentDivisionsProvider(
            'tournament-1',
          ).overrideWith((ref) async => divisions),
        ],
        child: _app(
          tournament,
          managementRepository: _EmptyTournamentManagementRepository(),
          tournamentRepository: _EmptyTournamentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openTab(tester, l10n.tournamentManagementTabAthletes);
    expect(
      find.byKey(const ValueKey('athlete-division-body-div-empty')),
      findsOneWidget,
    );

    expect(find.byType(TournamentManagementPeopleSection), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementApplicationsEmpty),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('android back closes an opened section before leaving the hub', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.manageSettingsInfoSection).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementName), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementName), findsNothing);
    expect(find.byType(TournamentManagementHubScreen), findsOneWidget);
    expect(
      find.text(l10n.manageSettingsInfoSection).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving the information page with unsaved edits asks first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _EmptyTournamentManagementRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openSettings(tester);
    await tester.tap(find.text(l10n.manageSettingsInfoSection).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Edited name');
    await tester.pump();

    // Back asks; "Cancel" keeps the page and the edit.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementDiscardTitle), findsOneWidget);
    await tester.tap(find.text(l10n.tournamentManagementCancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementName), findsOneWidget);

    // Confirming the discard closes the page.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementDiscardConfirm));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementName), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bracket tab embeds an editable bracket workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openTab(tester, l10n.tournamentManagementTabBracket);

    final bracket = tester.widget<BracketViewScreen>(
      find.byType(BracketViewScreen).first,
    );
    expect(bracket.isEmbedded, isTrue);
    expect(bracket.canEditBracket, isTrue);
  });

  testWidgets('divisions tab sits right after the overview tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _LifecycleRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    final tabs = tester
        .widgetList<Tab>(find.byType(Tab))
        .map((tab) => tab.text)
        .toList();
    expect(tabs, [
      l10n.tournamentManagementOverview,
      l10n.tournamentManagementTabDivisions,
      l10n.tournamentManagementTabAthletes,
      l10n.tournamentManagementTabBracket,
      l10n.tournamentManagementSchedule,
      l10n.tournamentManagementTabSettings,
      l10n.tournamentManagementTabResults,
    ]);

    await _openTab(tester, l10n.tournamentManagementTabDivisions);
    expect(find.byType(TournamentManagementDivisionsSection), findsOneWidget);
  });

  testWidgets('bracket tab "Quản lý" chip jumps to the divisions tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        _tournament('in_progress'),
        managementRepository: _LifecycleRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openTab(tester, l10n.tournamentManagementTabBracket);
    tester
        .widget<BracketViewScreen>(find.byType(BracketViewScreen).first)
        .onManageDivisions!();
    await tester.pumpAndSettle();

    expect(find.byType(TournamentManagementDivisionsSection), findsOneWidget);
  });

  testWidgets('settings tab no longer lists divisions (they have a tab)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();
    await _openSettings(tester);

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.tournamentManagementDivisions), findsNothing);
  });

  testWidgets('bracket tab gives organizers a manage-divisions action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(_app(_tournament('in_progress')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(TournamentManagementHubScreen));
    final l10n = AppLocalizations.of(context)!;
    await _openTab(tester, l10n.tournamentManagementTabBracket);

    final bracket = tester.widget<BracketViewScreen>(
      find.byType(BracketViewScreen).first,
    );
    // The action opens the divisions screen; its providers need the real
    // DioClient (.env), so only the wiring is asserted here.
    expect(bracket.onManageDivisions, isNotNull);
  });

  testWidgets(
    'overview tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(_app(_tournament('completed', quick: false)));
      await tester.pumpAndSettle();

      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final locationFinder = find.byKey(
        const ValueKey('tournament-overview-location-edit'),
      );
      expect(locationFinder, findsOneWidget);
      final locationRect = tester.getRect(locationFinder);

      final gap = locationRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(24.0));
    },
  );

  testWidgets(
    'athletes tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      final divisions = <Map<String, dynamic>>[
        {'id': 'div-mixed', 'name': 'Đôi Nam Nữ', 'matchType': 'DOUBLES'},
        {'id': 'div-men', 'name': 'Đơn nam', 'matchType': 'SINGLES'},
      ];
      final tournament = _tournament('in_progress', divisions: divisions);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => divisions),
          ],
          child: _app(
            tournament,
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _EmptyTournamentRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      final tabFinder = find.widgetWithText(
        Tab,
        l10n.tournamentManagementTabAthletes,
      );
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();
      // Cuộn lên 180px kéo trên outer header (tương ứng với ảnh người dùng gửi)
      await tester.dragFrom(const Offset(200, 100), const Offset(0, -180));
      await tester.pumpAndSettle();

      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final firstRow = find.byKey(
        const ValueKey('athlete-division-div-mixed'),
      );
      expect(firstRow, findsOneWidget);
      final rowRect = tester.getRect(firstRow);

      final gap = rowRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(24.0));
    },
  );

  testWidgets(
    'tournament title keeps a steady gap below the banner frame while the header collapses',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        _app(
          _tournament(
            'in_progress',
            bannerUrl: 'https://images.example/tournament-banner.jpg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final dy in [0.0, -40.0, -80.0]) {
        if (dy != 0.0) {
          await tester.dragFrom(const Offset(200, 300), Offset(0, dy));
          await tester.pumpAndSettle();
        }
        // Đáy khung cắt là phần người dùng nhìn thấy; ảnh parallax bên trong
        // có thể kéo dài hơn khung nên không dùng làm mốc.
        final frameBottom = tester
            .getRect(find.byType(FlexibleSpaceBar))
            .bottom;
        final titleTop = tester.getRect(find.text('City Pickleball Cup')).top;
        expect(
          titleTop - frameBottom,
          inInclusiveRange(0.0, 24.0),
          reason:
              'sau khi kéo thêm $dy: đáy khung=$frameBottom, đỉnh tên giải=$titleTop',
        );
      }
    },
  );

  testWidgets(
    'TC-EDIT-BANNER: banner edit button and logo stay inside the visible banner after a small scroll',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        _app(
          _tournament(
            'in_progress',
            bannerUrl: 'https://images.example/tournament-banner.jpg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final dy in [0.0, -30.0, -60.0]) {
        if (dy != 0.0) {
          await tester.dragFrom(const Offset(200, 300), Offset(0, dy));
          await tester.pumpAndSettle();
        }
        final frameBottom = tester
            .getRect(find.byType(FlexibleSpaceBar))
            .bottom;
        final editBottom = tester
            .getRect(find.byKey(const ValueKey('tournament-overview-banner-edit')))
            .bottom;
        final logoBottom = tester
            .getRect(find.byKey(const ValueKey('tournament-overview-logo')))
            .bottom;
        expect(
          editBottom,
          lessThanOrEqualTo(frameBottom + 0.5),
          reason: 'edit button cut off after drag $dy',
        );
        expect(
          logoBottom,
          lessThanOrEqualTo(frameBottom + 0.5),
          reason: 'logo cut off after drag $dy',
        );
      }
    },
  );

  testWidgets(
    'bracket tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentRepositoryProvider.overrideWithValue(
              _EmptyTournamentRepository(),
            ),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: _app(
            _tournament('in_progress'),
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _EmptyTournamentRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      final tabFinder = find.widgetWithText(
        Tab,
        l10n.tournamentManagementTabBracket,
      );
      // The strip scrolls sideways now that it has six tabs.
      await tester.ensureVisible(tabFinder);
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(200, 100), const Offset(0, -180));
      await tester.pumpAndSettle();

      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final bracketFinder = find.byType(BracketViewScreen);
      expect(bracketFinder, findsOneWidget);
      final bracketRect = tester.getRect(bracketFinder);

      final gap = bracketRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(24.0));
    },
  );

  testWidgets(
    'schedule tab content is positioned immediately below pinned tab strip without excessive gap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentRepositoryProvider.overrideWithValue(
              _EmptyTournamentRepository(),
            ),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(_tournament('in_progress'))),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: _app(
            _tournament('in_progress'),
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _EmptyTournamentRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(TournamentManagementHubScreen),
      );
      final l10n = AppLocalizations.of(context)!;
      await _openTab(tester, l10n.tournamentManagementSchedule);
      // Không drag thêm (đo ở vị trí sau khi chọn tab)
      final tabBarRect = tester.getRect(find.byType(TabBar).first);
      final iconFinder = find.byIcon(Icons.category_outlined);
      expect(iconFinder, findsOneWidget);
      final cardFinder = find
          .ancestor(of: iconFinder, matching: find.byType(Container))
          .first;
      final cardRect = tester.getRect(cardFinder);

      final gap = cardRect.top - tabBarRect.bottom;
      expect(gap, greaterThanOrEqualTo(0.0));
      expect(gap, lessThanOrEqualTo(72.0));
    },
  );

  group('athletes tab as expandable division rows', () {
    final divisions = <Map<String, dynamic>>[
      {'id': 'div-mixed', 'name': 'Đôi Nam Nữ', 'matchType': 'DOUBLES'},
      {'id': 'div-men', 'name': 'Đơn nam', 'matchType': 'SINGLES'},
    ];
    const participants = [
      OrganizerOpsParticipant(
        id: 'p-1',
        teamName: 'Danh – Luân',
        teamStatus: 'COMPLETE',
        isPaid: true,
        members: [
          OrganizerOpsMember(
            userId: 'u-danh',
            fullName: 'Danh',
            role: 'CAPTAIN',
          ),
          OrganizerOpsMember(userId: 'u-luan', fullName: 'Luân'),
        ],
        divisionId: 'div-mixed',
      ),
      OrganizerOpsParticipant(
        id: 'p-2',
        teamName: 'An – Bình',
        teamStatus: 'PENDING_APPROVAL',
        isPaid: false,
        members: [
          OrganizerOpsMember(userId: 'u-an', fullName: 'An'),
          OrganizerOpsMember(userId: 'u-binh', fullName: 'Bình'),
        ],
        divisionId: 'div-mixed',
      ),
      OrganizerOpsParticipant(
        id: 'p-4',
        teamName: 'Nhật Minh',
        teamStatus: 'PENDING_PARTNER',
        isPaid: false,
        members: [OrganizerOpsMember(userId: 'u-minh', fullName: 'Nhật Minh')],
        divisionId: 'div-mixed',
      ),
      OrganizerOpsParticipant(
        id: 'p-3',
        teamName: 'Cường',
        teamStatus: 'COMPLETE',
        isPaid: true,
        members: [OrganizerOpsMember(userId: 'u-cuong', fullName: 'Cường')],
        divisionId: 'div-men',
      ),
    ];

    Future<void> pumpAthletes(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      final tournament = _tournament('in_progress', divisions: divisions);
      final repository = _DivisionParticipantsRepository(participants);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => divisions),
          ],
          child: _app(
            tournament,
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await _openTab(tester, l10n.tournamentManagementTabAthletes);
    }

    final rowMixed = find.byKey(
      const ValueKey('athlete-division-div-mixed'),
    );
    final rowMen = find.byKey(const ValueKey('athlete-division-div-men'));
    final bodyMixed = find.byKey(
      const ValueKey('athlete-division-body-div-mixed'),
    );
    final bodyMen = find.byKey(const ValueKey('athlete-division-body-div-men'));

    testWidgets('shows one chip per division, the first one open, no old segment', (
      tester,
    ) async {
      await pumpAthletes(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;

      expect(rowMixed, findsOneWidget);
      expect(rowMen, findsOneWidget);
      expect(find.text('Đôi Nam Nữ'), findsOneWidget);
      expect(find.text('Đơn nam'), findsOneWidget);
      // Nội dung đầu tiên mở sẵn, nội dung kia chưa dựng; segment cũ không còn.
      expect(bodyMixed, findsOneWidget);
      expect(bodyMen, findsNothing);
      expect(find.text(l10n.opsRoster), findsNothing);
    });

    testWidgets('a chosen division shows only its own teams', (
      tester,
    ) async {
      await pumpAthletes(tester);


      expect(bodyMixed, findsOneWidget);
      expect(find.text('Danh – Luân'), findsOneWidget);
      // Đội của nội dung khác không lọt vào row này.
      expect(find.text('Cường'), findsNothing);
    });

    testWidgets('choosing another chip replaces the previous division', (
      tester,
    ) async {
      await pumpAthletes(tester);
      expect(bodyMixed, findsOneWidget);

      await tester.tap(rowMen);
      await tester.pumpAndSettle();

      expect(bodyMen, findsOneWidget);
      expect(bodyMixed, findsNothing);
    });

    testWidgets('tapping the selected chip again keeps its division open', (
      tester,
    ) async {
      await pumpAthletes(tester);
      expect(bodyMixed, findsOneWidget);

      await tester.tap(rowMixed);
      await tester.pumpAndSettle();
      expect(bodyMixed, findsOneWidget);
    });

    testWidgets('expanded row shows the Excel import and template buttons', (
      tester,
    ) async {
      await pumpAthletes(tester);


      expect(
        find.byKey(const ValueKey('athletes-import-excel')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('athletes-more')), findsOneWidget);
    });

    testWidgets('tapping Excel import opens the roster import sheet', (
      tester,
    ) async {
      await pumpAthletes(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;


      final importButton = find.byKey(const ValueKey('athletes-import-excel'));
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.rosterImportTitle), findsOneWidget);
    });

    testWidgets('pending registration lives inside its own division row', (
      tester,
    ) async {
      await pumpAthletes(tester);


      expect(find.text('An – Bình'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('participant-approve-p-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('participant-reject-p-2')),
        findsOneWidget,
      );
    });

    final teamPairKey = const ValueKey('athlete-team-row-p-1');

    Future<void> openMixed(WidgetTester tester) => pumpAthletes(tester);

    testWidgets('doubles team opens the detail sheet with members', (
      tester,
    ) async {
      await openMixed(tester);

      final row = find.byKey(teamPairKey);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Bấm dòng đội mở sheet hồ sơ chi tiết (thay card mở rộng cũ).
      final sheet = find.byType(ParticipantDetailSheet);
      expect(sheet, findsOneWidget);
      // Mỗi VĐV trong đội có avatar riêng (chữ cái đầu khi chưa có ảnh).
      expect(
        find.descendant(of: sheet, matching: find.byType(RankAvatar)),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Danh')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Luân')),
        findsOneWidget,
      );
    });

    testWidgets('single-member pair still opens the detail sheet', (
      tester,
    ) async {
      await openMixed(tester);
      final row = find.byKey(const ValueKey('athlete-team-row-p-4'));
      await tester.ensureVisible(row);
      // Nội dung đôi không còn mũi tên mở rộng inline; bấm dòng mở sheet.
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.expand_more_rounded),
        ),
        findsNothing,
      );
      await tester.tap(
        find.descendant(of: row, matching: find.text('Nhật Minh')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ParticipantDetailSheet), findsOneWidget);
      // Tên VĐV hiện ở cả tiêu đề sheet và dòng thành viên.
      expect(
        find.descendant(
          of: find.byType(ParticipantDetailSheet),
          matching: find.text('Nhật Minh'),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('single-player team opens the detail sheet too', (
      tester,
    ) async {
      await pumpAthletes(tester);
      await tester.tap(rowMen);
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('athlete-team-row-p-3'));
      expect(row, findsOneWidget);
      // Đội đơn: không mũi tên mở rộng; bấm dòng mở sheet hồ sơ.
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.expand_more_rounded),
        ),
        findsNothing,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(ParticipantDetailSheet), findsOneWidget);
    });

    testWidgets('team-sport tournament teams open the detail sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      final footballDivisions = <Map<String, dynamic>>[
        {'id': 'div-fb', 'name': 'Sân 7', 'matchType': 'SINGLES'},
      ];
      final tournament = _tournament(
        'in_progress',
        sport: 'football',
        divisions: footballDivisions,
      );
      // Bóng đá: teamSize có giá trị -> môn đồng đội.
      expect(tournament.teamSize, isNotNull);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => footballDivisions),
          ],
          child: _app(
            tournament,
            managementRepository: _EmptyTournamentManagementRepository(),
            tournamentRepository: _DivisionParticipantsRepository(const [
              OrganizerOpsParticipant(
                id: 'p-fb',
                teamName: 'FC Một',
                teamStatus: 'COMPLETE',
                isPaid: true,
                members: [OrganizerOpsMember(userId: 'u-fb', fullName: 'Hùng')],
                divisionId: 'div-fb',
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await _openTab(tester, l10n.tournamentManagementTabAthletes);
      // One division: the strip is hidden and its body is open already.
      final team = find.byKey(const ValueKey('athlete-team-row-p-fb'));
      await tester.ensureVisible(team);
      await tester.tap(team);
      await tester.pumpAndSettle();
      expect(find.byType(ParticipantDetailSheet), findsOneWidget);
    });

    testWidgets('pending approval actions sit on the team row itself', (
      tester,
    ) async {
      await openMixed(tester);
      final row = find.byKey(const ValueKey('athlete-team-row-p-2'));

      // Chưa mở đội vẫn thấy ✓ / ✕ ngay trên dòng.
      expect(
        find.descendant(
          of: row,
          matching: find.byKey(const ValueKey('participant-approve-p-2')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.byKey(const ValueKey('participant-reject-p-2')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('waiting-for-partner status uses the short label', (
      tester,
    ) async {
      await openMixed(tester);
      expect(find.text('Chờ ghép'), findsOneWidget);
      expect(find.text('Đang chờ ghép đồng đội'), findsNothing);
    });

    testWidgets('team rows are flat: no card border inside the division row', (
      tester,
    ) async {
      await openMixed(tester);
      final row = find.byKey(const ValueKey('athlete-team-row-p-1'));
      expect(row, findsOneWidget);
      // Không còn box viền bao đội (box trong box).
      final bordered = find.descendant(
        of: row,
        matching: find.byWidgetPredicate((w) {
          if (w is! Container) return false;
          final d = w.decoration;
          return d is BoxDecoration &&
              d.border is Border &&
              d.borderRadius != null;
        }),
      );
      expect(bordered, findsNothing);

      // Nội dung nới ra sát mép: bỏ padding ngang 16 của tab.
      final rowRect = tester.getRect(bodyMixed);
      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(rowRect.left, lessThanOrEqualTo(0.5));
      expect(rowRect.right, greaterThanOrEqualTo(screen - 0.5));

      // Dòng đội cũng sát mép: không còn lề ngang bao quanh danh sách đội.
      final teamRect = tester.getRect(row);
      expect(teamRect.left, lessThanOrEqualTo(0.5));
      expect(teamRect.right, greaterThanOrEqualTo(screen - 0.5));
      // Bỏ lề không được gây tràn: hàng tên + trạng thái + mũi tên vừa khung.
      expect(tester.takeException(), isNull);
    });

    testWidgets('mock data and wildcard buttons open their own sheets', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      final tournament = _tournament('in_progress', divisions: divisions);
      final management = _RecordingManagementRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => divisions),
          ],
          child: _app(
            tournament,
            managementRepository: management,
            tournamentRepository: _DivisionParticipantsRepository(participants),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await _openTab(tester, l10n.tournamentManagementTabAthletes);


      // Nút VĐV ảo mở đúng sheet ảo, chưa sinh gì.
      final moreButton = find.byKey(const ValueKey('athletes-more'));
      await tester.ensureVisible(moreButton);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('athletes-mock-data')));
      await tester.pumpAndSettle();
      expect(find.byType(MockParticipantsSheet), findsOneWidget);
      expect(management.seededMockNames, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('tournament-manage-sheet-close')),
      );
      await tester.pumpAndSettle();

      // Nút đặc cách mở đúng sheet đặc cách.
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('athletes-wildcard')));
      await tester.pumpAndSettle();
      expect(find.byType(WildcardSheet), findsOneWidget);
      expect(management.reservedSlotContacts, isEmpty);
    });

    Future<_RecordingManagementRepository> addAthleteFromRow(
      WidgetTester tester, {
      required num effectiveEntryFee,
    }) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      final feeDivisions = <Map<String, dynamic>>[
        {
          'id': 'div-mixed',
          'name': 'Đôi Nam Nữ',
          'matchType': 'DOUBLES',
          'effectiveEntryFee': effectiveEntryFee,
        },
      ];
      final tournament = _tournament(
        'REGISTRATION_OPEN',
        divisions: feeDivisions,
      );
      final management = _RecordingManagementRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introTeamsProvider(
              'tournament-1',
            ).overrideWith((ref) async => const []),
            tournamentProvider(
              'tournament-1',
            ).overrideWith((ref) => Stream.value(tournament)),
            tournamentDivisionsProvider(
              'tournament-1',
            ).overrideWith((ref) async => feeDivisions),
          ],
          child: _app(
            tournament,
            managementRepository: management,
            tournamentRepository: _DivisionParticipantsRepository(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TournamentManagementHubScreen)),
      )!;
      await _openTab(tester, l10n.tournamentManagementTabAthletes);

      final addButton = find.text(l10n.opsAddAthlete);
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      final directTab = find.text(l10n.opsAddAthleteDirect);
      await tester.ensureVisible(directTab);
      await tester.tap(directTab);
      await tester.pumpAndSettle();
      final nameField = find.byKey(const ValueKey('add-athlete-direct-name'));
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Paid athlete');
      await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
      await tester.pumpAndSettle();
      return management;
    }

    testWidgets('add athlete from a row with a fee does not auto-approve', (
      tester,
    ) async {
      final management = await addAthleteFromRow(
        tester,
        effectiveEntryFee: 100,
      );

      expect(management.directNames, ['Paid athlete']);
      // Phí dương: VĐV phải chờ duyệt, không được tự động duyệt.
      expect(management.statusUpdates, isEmpty);
    });

    testWidgets('add athlete from a free row auto-approves', (tester) async {
      final management = await addAthleteFromRow(tester, effectiveEntryFee: 0);

      expect(management.directNames, ['Paid athlete']);
      // Đối chứng: cùng luồng nhưng phí 0 thì sheet tự duyệt. Nếu phí không
      // tới được sheet, hai test này sẽ cho cùng một kết quả.
      expect(management.statusUpdates, isNotEmpty);
    });
  });
}
