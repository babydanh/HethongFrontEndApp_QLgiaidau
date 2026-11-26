import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/services/manage_role_access.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manager_guard.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// [outcome] is the role the Backend answers, or an error to throw.
class _ProbeRepository implements ITournamentRepository {
  _ProbeRepository(this.outcome);

  final Object outcome;
  int probes = 0;

  @override
  Future<ManageRole> getManageRole(String tournamentId) async {
    probes++;
    final value = outcome;
    if (value is ManageRole) return value;
    throw value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DioException _status(int code) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
  ),
);

Future<_ProbeRepository> _pump(
  WidgetTester tester,
  Object outcome, {
  bool managerOnly = false,
}) async {
  final repo = _ProbeRepository(outcome);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tournamentRepositoryProvider.overrideWith((ref) => repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: TournamentManagerGuard(
          tournamentId: 't1',
          managerOnly: managerOnly,
          builder: (context, role) => Text('MAN_HINH_QUAN_LY:${role.name}'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

const _noPermission = 'Bạn không có quyền vận hành giải đấu này.';

void main() {
  testWidgets(
    'TC-REF-MODE-APP-07 a stranger (403) sees no-permission, never the page',
    (tester) async {
      final repo = await _pump(tester, _status(403));
      expect(find.textContaining('MAN_HINH_QUAN_LY'), findsNothing);
      expect(find.text(_noPermission), findsOneWidget);
      expect(repo.probes, 1);
    },
  );

  testWidgets('TC-REF-MODE-APP-08 a manager enters with the manager role', (
    tester,
  ) async {
    await _pump(tester, ManageRole.manager);
    expect(find.text('MAN_HINH_QUAN_LY:manager'), findsOneWidget);
  });

  testWidgets('TC-REF-MODE-APP-09 an accepted referee enters as referee', (
    tester,
  ) async {
    await _pump(tester, ManageRole.referee);
    expect(find.text('MAN_HINH_QUAN_LY:referee'), findsOneWidget);
  });

  testWidgets('TC-REF-MODE-APP-10 a manager-only page turns a referee away', (
    tester,
  ) async {
    await _pump(tester, ManageRole.referee, managerOnly: true);
    expect(find.textContaining('MAN_HINH_QUAN_LY'), findsNothing);
    expect(find.text(_noPermission), findsOneWidget);
  });

  testWidgets(
    'TC-REF-MODE-APP-10b a referee of a DRAFT/PENDING tournament (404) is turned away',
    (tester) async {
      await _pump(tester, _status(404));
      expect(find.textContaining('MAN_HINH_QUAN_LY'), findsNothing);
      expect(find.text(_noPermission), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  testWidgets('shows a retry (not the page) on a server error', (tester) async {
    await _pump(tester, _status(500));
    expect(find.textContaining('MAN_HINH_QUAN_LY'), findsNothing);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
