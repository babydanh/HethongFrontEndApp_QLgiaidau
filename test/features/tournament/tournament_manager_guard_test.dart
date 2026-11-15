import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manager_guard.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProbeRepository implements ITournamentRepository {
  _ProbeRepository(this.outcome);

  final Object? outcome;
  int probes = 0;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async {
    probes++;
    final error = outcome;
    if (error != null) throw error;
    return const [];
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

Future<_ProbeRepository> _pump(WidgetTester tester, Object? outcome) async {
  final repo = _ProbeRepository(outcome);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tournamentRepositoryProvider.overrideWith((ref) => repo)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: TournamentManagerGuard(
          tournamentId: 't1',
          child: Text('MAN_HINH_QUAN_LY'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows no-permission and never mounts the child on 403', (
    tester,
  ) async {
    final repo = await _pump(tester, _status(403));
    expect(find.text('MAN_HINH_QUAN_LY'), findsNothing);
    expect(
      find.text('Bạn không có quyền vận hành giải đấu này.'),
      findsOneWidget,
    );
    expect(repo.probes, 1);
  });

  testWidgets('shows the child when the organizer probe succeeds', (
    tester,
  ) async {
    await _pump(tester, null);
    expect(find.text('MAN_HINH_QUAN_LY'), findsOneWidget);
  });

  testWidgets('shows a retry (not the child) on a server error', (
    tester,
  ) async {
    await _pump(tester, _status(500));
    expect(find.text('MAN_HINH_QUAN_LY'), findsNothing);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
