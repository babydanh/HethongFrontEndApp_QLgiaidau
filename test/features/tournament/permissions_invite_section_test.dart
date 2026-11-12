import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _email = 'invitee@example.test';
const _declinedEmail = 'declined@example.test';

class _FakeRepo implements TournamentManagementRepository {
  _FakeRepo({this.staff = const [], this.referees = const []});

  List<Map<String, dynamic>> staff;
  List<Map<String, dynamic>> referees;
  Completer<void>? holdAddReferee;
  bool failMutations = false;

  final addedReferees = <String>[];
  final removedReferees = <String>[];
  final addedStaff = <(String, String)>[];
  final removedStaff = <String>[];

  @override
  Future<List<Map<String, dynamic>>> getStaff(String id) async => staff;

  @override
  Future<List<Map<String, dynamic>>> getReferees(String id) async => referees;

  @override
  Future<void> addReferee(String id, String email) async {
    addedReferees.add(email);
    if (failMutations) throw Exception('boom');
    await holdAddReferee?.future;
  }

  @override
  Future<void> removeReferee(String id, String refereeId) async {
    removedReferees.add(refereeId);
    if (failMutations) throw Exception('boom');
  }

  @override
  Future<Map<String, dynamic>> addStaff(
    String id,
    String email,
    String role,
  ) async {
    addedStaff.add((email, role));
    if (failMutations) throw Exception('boom');
    return {};
  }

  @override
  Future<void> removeStaff(String id, String userId) async {
    removedStaff.add(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _referee(String id, String status, {String? email}) => {
  'id': id,
  'userId': 'u-$id',
  'status': status,
  'fullName': 'Referee $id',
  'email': email ?? '$id@example.test',
};

Tournament _tournament() => Tournament.fromJson({
  'name': 'Permissions Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'registration',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'registrationMode': 'APPROVAL',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Future<AppLocalizations> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementPeopleSection(
            tournament: _tournament(),
            showRegistration: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
}

Future<void> _invite(
  WidgetTester tester, {
  required String email,
  String role = 'REFEREE',
}) async {
  await tester.tap(find.byKey(Key('permissions-role-$role')));
  await tester.pump();
  await tester.enterText(
    find.byKey(const Key('permissions-invite-email')),
    email,
  );
}

/// Opens the row's three-dot sheet and taps its single action.
Future<void> _pickRowAction(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('permissions-row-sheet-action')));
  await tester.pumpAndSettle();
}

Finder _confirmButton() => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(FilledButton),
);

void main() {
  testWidgets('inviting a referee calls addReferee once, even on double tap', (
    tester,
  ) async {
    final repo = _FakeRepo()..holdAddReferee = Completer<void>();
    await _pump(tester, repo);

    await _invite(tester, email: _email);
    final send = find.byKey(const Key('permissions-invite-send'));
    await tester.tap(send);
    await tester.pump();
    await tester.tap(send, warnIfMissed: false);
    await tester.pump();
    expect(repo.addedReferees, [_email]);

    repo.holdAddReferee!.complete();
    await tester.pumpAndSettle();
    expect(repo.addedReferees, [_email]);
    final field = tester.widget<TextField>(
      find.byKey(const Key('permissions-invite-email')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('co-organizer invite goes to addStaff with its role', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);

    await _invite(tester, email: _email, role: 'CO_ORGANIZER');
    await tester.tap(find.byKey(const Key('permissions-invite-send')));
    await tester.pumpAndSettle();

    expect(repo.addedStaff, [(_email, 'CO_ORGANIZER')]);
    expect(repo.addedReferees, isEmpty);
  });

  testWidgets('invalid email never reaches the API and shows an error', (
    tester,
  ) async {
    final repo = _FakeRepo();
    final l10n = await _pump(tester, repo);

    await _invite(tester, email: 'not-an-email');
    await tester.tap(find.byKey(const Key('permissions-invite-send')));
    await tester.pumpAndSettle();

    expect(repo.addedReferees, isEmpty);
    expect(repo.addedStaff, isEmpty);
    expect(
      find.text(l10n.tournamentManagementInviteEmailInvalid),
      findsOneWidget,
    );
  });

  testWidgets('resend on a declined referee calls addReferee with its email', (
    tester,
  ) async {
    final repo = _FakeRepo(
      referees: [_referee('d1', 'DECLINED', email: _declinedEmail)],
    );
    await _pump(tester, repo);

    await _pickRowAction(tester);
    await tester.pumpAndSettle();
    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();

    expect(repo.addedReferees, [_declinedEmail]);
  });

  testWidgets('revoke on an invited referee calls removeReferee with its id', (
    tester,
  ) async {
    final repo = _FakeRepo(referees: [_referee('i1', 'INVITED')]);
    await _pump(tester, repo);

    await _pickRowAction(tester);
    await tester.pumpAndSettle();
    await tester.tap(_confirmButton());
    await tester.pumpAndSettle();

    expect(repo.removedReferees, ['i1']);
  });

  testWidgets('cancelling the confirm dialog makes no API call', (
    tester,
  ) async {
    final repo = _FakeRepo(referees: [_referee('i1', 'INVITED')]);
    final l10n = await _pump(tester, repo);

    await _pickRowAction(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementCancel));
    await tester.pumpAndSettle();

    expect(repo.removedReferees, isEmpty);
  });

  testWidgets(
    'TC-APP-REF-ADD-02 accepted referee can be removed after confirming',
    (tester) async {
      final repo = _FakeRepo(referees: [_referee('a1', 'ACCEPTED')]);
      final l10n = await _pump(tester, repo);

      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text(l10n.tournamentManagementRemove), findsOneWidget);
      expect(find.text(l10n.tournamentManagementResend), findsNothing);
      expect(find.text(l10n.tournamentManagementRevoke), findsNothing);

      await tester.tap(find.byKey(const Key('permissions-row-sheet-action')));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.tournamentManagementRemoveRefereeConfirm('Referee a1')),
        findsOneWidget,
      );
      await tester.tap(_confirmButton());
      await tester.pumpAndSettle();

      expect(repo.removedReferees, ['a1']);
      expect(repo.removedStaff, isEmpty);
      expect(
        find.text(l10n.tournamentManagementRefereeRemoved),
        findsOneWidget,
      );
    },
  );

  testWidgets('role filter keeps only referee rows', (tester) async {
    final repo = _FakeRepo(
      staff: [
        {'userId': 'u1', 'fullName': 'Staff One', 'role': 'SPECTATOR'},
      ],
      referees: [_referee('i1', 'INVITED')],
    );
    await _pump(tester, repo);
    expect(find.text('Staff One'), findsOneWidget);

    await tester.tap(find.byKey(const Key('permissions-filter-REFEREE')));
    await tester.pumpAndSettle();

    expect(find.text('Staff One'), findsNothing);
    expect(find.text('Referee i1'), findsOneWidget);
  });

  testWidgets('failed mutation keeps the list and re-enables the button', (
    tester,
  ) async {
    final repo = _FakeRepo(referees: [_referee('i1', 'INVITED')])
      ..failMutations = true;
    final l10n = await _pump(tester, repo);

    await _invite(tester, email: _email);
    await tester.tap(find.byKey(const Key('permissions-invite-send')));
    await tester.pumpAndSettle();

    expect(find.text('Referee i1'), findsOneWidget);
    expect(find.text(l10n.tournamentManagementActionError), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    final send = tester.widget<FilledButton>(
      find.byKey(const Key('permissions-invite-send')),
    );
    expect(send.onPressed, isNotNull);
  });

  testWidgets('does not overflow at 320 width', (tester) async {
    final repo = _FakeRepo(
      staff: [
        {
          'userId': 'u1',
          'fullName': 'A very long staff member name ' * 3,
          'role': 'CO_ORGANIZER',
        },
      ],
      referees: [
        _referee('d1', 'DECLINED'),
        _referee('i1', 'INVITED'),
        _referee('a1', 'ACCEPTED'),
      ],
    );
    await _pump(tester, repo, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
  });
}
