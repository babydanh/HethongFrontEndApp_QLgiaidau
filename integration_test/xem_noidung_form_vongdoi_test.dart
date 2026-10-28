import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_editor_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/registration_form_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/xem.dart';

/// Division editor accordion, custom registration form and the lifecycle step
/// bar, on fake data only (no Backend, no network).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initXem);

  testWidgets('xem: sheet noi dung thi dau accordion', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _ManagementRepository(),
          ),
          tournamentRepositoryProvider.overrideWithValue(_StageRepository()),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: const ValueKey('open-sheet'),
                onPressed: () => DivisionEditorSheet.show(
                  context,
                  tournament: _tournament(status: 'REGISTRATION'),
                ),
                child: const Text('Mo sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await settle(tester);
    await shooter.snap('noi-dung-thi-dau-dong');

    await tester.tap(find.byKey(const ValueKey('division-editor-section-elo')));
    await settle(tester);
    await shooter.snap('noi-dung-thi-dau-muc-elo');
  });

  testWidgets('xem: form dang ky tuy bien', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _ManagementRepository(),
          ),
        ],
        home: RegistrationFormEditorScreen(
          tournament: _tournament(
            status: 'REGISTRATION_OPEN',
            fields: [
              _field('skill', 'Trinh do thi dau', required: true),
              _field(
                'shirt',
                'Size ao',
                type: 'SELECT',
                options: ['S', 'M', 'L'],
              ),
              _field('note', 'Ghi chu them'),
            ],
          ),
          answeredFieldIds: const {'skill'},
        ),
      ),
    );
    await shooter.snap('form-dang-ky-tuy-bien');
  });

  testWidgets('xem: thanh buoc vong doi giai', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _ManagementRepository(),
          ),
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentLifecycleCard(
              tournament: _tournament(
                status: 'REGISTRATION_OPEN',
                capacity: {
                  'occupiedTeamSlots': 16,
                  'maxTeamSlots': 16,
                  'isFull': true,
                },
              ),
            ),
          ),
        ),
      ),
    );
    await shooter.snap('vong-doi-dang-ky-day-doi');

    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _ManagementRepository(),
          ),
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentLifecycleCard(
              tournament: _tournament(status: 'IN_PROGRESS'),
            ),
          ),
        ),
      ),
    );
    await shooter.snap('vong-doi-dang-dien-ra');
  });
}

/// Management fake: fixed fee config and no writes.
class _ManagementRepository
    implements TournamentManagementRepository, TournamentSettingsRepository {
  @override
  Future<Map<String, dynamic>> getFeesConfig() async => {
    'feeClub': 0,
    'feePublicRanked': 0,
    'feePublicUnranked': 0,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StageRepository implements ITournamentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _field(
  String id,
  String label, {
  String type = 'TEXT',
  List<String>? options,
  bool required = false,
}) => {
  'id': id,
  'label': label,
  'type': type,
  'required': required,
  'options': ?options,
};

Tournament _tournament({
  String status = 'DRAFT',
  Map<String, dynamic>? capacity,
  List<Map<String, dynamic>> fields = const [],
}) => Tournament.fromJson({
  'name': 'Giai thu nghiem',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 16,
  'entryFee': '50000',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  'capacity': ?capacity,
  'divisions': [
    {'id': 'div-a', 'name': 'Doi nam', 'matchType': 'DOUBLES'},
  ],
  'tournamentConfig': {
    'location': {'city': 'Ha Noi'},
    'registrationForm': {
      'version': 1,
      'status': 'PUBLISHED',
      'divisionIds': ['div-a'],
      'fields': fields,
    },
  },
}, 'tournament-1');
