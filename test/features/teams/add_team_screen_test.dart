import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';
import 'package:app_quanly_giaidau/features/teams/screens/add_team_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _tournamentId = 'tour-teams';

/// Repository giả ghi lại lệnh ghi; `failWith` / `gate` để mô phỏng lỗi và chờ.
class _FakeTeamRepository implements ITeamRepository {
  final List<Team> created = [];
  final List<({String teamId, Map<String, dynamic> data})> updated = [];
  Object? failWith;
  Completer<void>? gate;

  Future<void> _maybeWait() async {
    await gate?.future;
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<Team> create(String tournamentId, Team team) async {
    await _maybeWait();
    created.add(team);
    return team;
  }

  @override
  Future<void> update(
    String tournamentId,
    String teamId,
    Map<String, dynamic> data,
  ) async {
    await _maybeWait();
    updated.add((teamId: teamId, data: data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Tournament _tournament(String status) => Tournament.fromJson({
  'name': 'Giải thử',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

Team _existingTeam({List<String> members = const ['An', 'Bình', 'Chi']}) =>
    Team(
      id: 'team-7',
      name: 'Đội Sấm sét',
      members: members,
      contactEmail: 'doi@example.com',
      qrCode: 'VDV_ABC123',
      createdAt: DateTime.utc(2026, 1, 2),
    );

/// Màn gọi `TeamService` đọc `tournamentProvider` đồng bộ nên cần có widget
/// đang theo dõi nó, như các màn thật trong app.
class _KeepTournamentAlive extends ConsumerWidget {
  const _KeepTournamentAlive({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tournamentProvider(_tournamentId));
    return child;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeTeamRepository repo, {
  Team? teamToEdit,
  Tournament? tournament,
  bool tournamentLoads = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/add'),
              child: const Text('MỞ FORM'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => _KeepTournamentAlive(
              child: AddTeamScreen(
                tournamentId: _tournamentId,
                teamToEdit: teamToEdit,
              ),
            ),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        teamRepositoryProvider.overrideWithValue(repo),
        tournamentProvider(_tournamentId).overrideWith(
          (ref) => tournamentLoads
              ? Stream.value(tournament ?? _tournament('registration'))
              : Stream<Tournament?>.value(null),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('MỞ FORM'));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, int index) => tester
    .widget<TextFormField>(find.byType(TextFormField).at(index))
    .controller!
    .text;

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  Finder fields() => find.byType(TextFormField);
  Finder removeButtons() => find.byIcon(Icons.remove_circle_outline);
  Finder saveButton() => find.widgetWithText(ElevatedButton, l10n.teamAdd_save);

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
  }

  group('tạo mới', () {
    testWidgets(
      'hiện tiêu đề tạo, tên rỗng, một ô thành viên và chưa có nút xoá',
      (tester) async {
        await _pump(tester, _FakeTeamRepository());

        expect(find.text(l10n.teamAdd_createTitle), findsOneWidget);
        expect(find.text(l10n.teamAdd_editTitle), findsNothing);
        // tên + 1 thành viên + email
        expect(fields(), findsNWidgets(3));
        expect(find.text(l10n.teamAdd_memberHint(1)), findsOneWidget);
        expect(removeButtons(), findsNothing);
        expect(saveButton(), findsOneWidget);
      },
    );

    testWidgets('bỏ trống tên: báo bắt buộc và không ghi gì', (tester) async {
      final repo = _FakeTeamRepository();
      await _pump(tester, repo);

      await save(tester);

      expect(find.text(l10n.teamAdd_nameRequired), findsOneWidget);
      expect(repo.created, isEmpty);
      expect(find.text(l10n.teamAdd_createTitle), findsOneWidget);
    });

    testWidgets('tên chỉ gồm khoảng trắng cũng bị từ chối', (tester) async {
      final repo = _FakeTeamRepository();
      await _pump(tester, repo);

      await tester.enterText(fields().at(0), '    ');
      await save(tester);

      expect(find.text(l10n.teamAdd_nameRequired), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets(
      'nút Thêm sinh thêm ô thành viên đánh số tiếp và hiện nút xoá',
      (tester) async {
        await _pump(tester, _FakeTeamRepository());

        await tester.tap(find.text(l10n.teamAdd_add));
        await tester.pump();
        await tester.tap(find.text(l10n.teamAdd_add));
        await tester.pump();

        expect(fields(), findsNWidgets(5));
        expect(find.text(l10n.teamAdd_memberHint(2)), findsOneWidget);
        expect(find.text(l10n.teamAdd_memberHint(3)), findsOneWidget);
        expect(removeButtons(), findsNWidgets(3));
      },
    );

    testWidgets(
      'xoá ô thành viên giữa danh sách giữ nguyên chữ của các ô còn lại',
      (tester) async {
        await _pump(tester, _FakeTeamRepository());
        await tester.tap(find.text(l10n.teamAdd_add));
        await tester.pump();
        await tester.tap(find.text(l10n.teamAdd_add));
        await tester.pump();
        await tester.enterText(fields().at(1), 'An');
        await tester.enterText(fields().at(2), 'Bình');
        await tester.enterText(fields().at(3), 'Chi');

        await tester.tap(removeButtons().at(1));
        await tester.pump();

        expect(fields(), findsNWidgets(4));
        expect(find.text('An'), findsOneWidget);
        expect(find.text('Bình'), findsNothing);
        expect(find.text('Chi'), findsOneWidget);
      },
    );

    testWidgets(
      'xoá về còn một ô thì nút xoá biến mất, không xoá được ô cuối',
      (tester) async {
        await _pump(tester, _FakeTeamRepository());
        await tester.tap(find.text(l10n.teamAdd_add));
        await tester.pump();

        await tester.tap(removeButtons().first);
        await tester.pump();

        expect(fields(), findsNWidgets(3));
        expect(removeButtons(), findsNothing);
      },
    );

    testWidgets(
      'lưu thành công: cắt khoảng trắng, bỏ thành viên trống, sinh mã QR VDV_ và quay lại',
      (tester) async {
        final repo = _FakeTeamRepository();
        await _pump(tester, repo);
        await tester.tap(find.text(l10n.teamAdd_add));
        await tester.pump();
        await tester.tap(find.text(l10n.teamAdd_add));
        await tester.pump();

        await tester.enterText(fields().at(0), '  Đội Mới  ');
        await tester.enterText(fields().at(1), ' Minh ');
        await tester.enterText(fields().at(2), '   ');
        await tester.enterText(fields().at(3), 'Lan');
        await tester.enterText(fields().at(4), ' lien-he@example.com ');
        await save(tester);

        final team = repo.created.single;
        expect(team.name, 'Đội Mới');
        expect(team.members, ['Minh', 'Lan']);
        expect(team.contactEmail, 'lien-he@example.com');
        expect(team.id, isNotEmpty);
        expect(team.qrCode, 'VDV_${team.id.substring(0, 6).toUpperCase()}');
        expect(find.text(l10n.teamAdd_created), findsOneWidget);
        expect(find.text('MỞ FORM'), findsOneWidget);
        expect(find.text(l10n.teamAdd_createTitle), findsNothing);
      },
    );

    testWidgets(
      'chỉ nhập tên: vẫn lưu được với danh sách thành viên và email rỗng',
      (tester) async {
        final repo = _FakeTeamRepository();
        await _pump(tester, repo);

        await tester.enterText(fields().at(0), 'VĐV Một Mình');
        await save(tester);

        final team = repo.created.single;
        expect(team.members, isEmpty);
        expect(team.contactEmail, '');
      },
    );

    testWidgets('hai lần tạo liên tiếp sinh hai id khác nhau', (tester) async {
      final repo = _FakeTeamRepository();
      await _pump(tester, repo);
      await tester.enterText(fields().at(0), 'Đội 1');
      await save(tester);
      await tester.tap(find.text('MỞ FORM'));
      await tester.pumpAndSettle();
      await tester.enterText(fields().at(0), 'Đội 2');
      await save(tester);

      expect(repo.created.map((t) => t.id).toSet(), hasLength(2));
    });

    testWidgets('đang lưu: nút khoá, hiện vòng quay, chưa đóng form', (
      tester,
    ) async {
      final repo = _FakeTeamRepository()..gate = Completer<void>();
      await _pump(tester, repo);
      await tester.enterText(fields().at(0), 'Đội Chậm');

      await tester.ensureVisible(saveButton());
      await tester.tap(saveButton());
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(l10n.teamAdd_save), findsNothing);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.text(l10n.teamAdd_createTitle), findsOneWidget);

      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(repo.created, hasLength(1));
      expect(find.text('MỞ FORM'), findsOneWidget);
    });

    testWidgets('kho dữ liệu lỗi: báo lỗi lưu, ở lại form và bật lại nút', (
      tester,
    ) async {
      final repo = _FakeTeamRepository()..failWith = StateError('db down');
      await _pump(tester, repo);
      await tester.enterText(fields().at(0), 'Đội Lỗi');

      await save(tester);

      expect(find.text(l10n.teamAdd_error), findsOneWidget);
      expect(find.text(l10n.teamAdd_createTitle), findsOneWidget);
      expect(_text(tester, 0), 'Đội Lỗi');
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    for (final status in ['in_progress', 'completed']) {
      testWidgets('giải đã $status: không cho thêm đội, báo lỗi', (
        tester,
      ) async {
        final repo = _FakeTeamRepository();
        await _pump(tester, repo, tournament: _tournament(status));
        await tester.enterText(fields().at(0), 'Đội Muộn');

        await save(tester);

        expect(repo.created, isEmpty);
        expect(find.text(l10n.teamAdd_error), findsOneWidget);
        expect(find.text(l10n.teamAdd_created), findsNothing);
      });
    }

    testWidgets('giải chưa tải được (null): không ghi, báo lỗi', (
      tester,
    ) async {
      final repo = _FakeTeamRepository();
      await _pump(tester, repo, tournamentLoads: false);
      await tester.enterText(fields().at(0), 'Đội Mồ Côi');

      await save(tester);

      expect(repo.created, isEmpty);
      expect(find.text(l10n.teamAdd_error), findsOneWidget);
    });
  });

  group('chỉnh sửa', () {
    testWidgets('điền sẵn tên, thành viên và email của đội, tiêu đề là Sửa', (
      tester,
    ) async {
      await _pump(tester, _FakeTeamRepository(), teamToEdit: _existingTeam());

      expect(find.text(l10n.teamAdd_editTitle), findsOneWidget);
      expect(find.text(l10n.teamAdd_createTitle), findsNothing);
      expect(_text(tester, 0), 'Đội Sấm sét');
      expect(
        [_text(tester, 1), _text(tester, 2), _text(tester, 3)],
        ['An', 'Bình', 'Chi'],
      );
      expect(_text(tester, 4), 'doi@example.com');
      expect(removeButtons(), findsNWidgets(3));
    });

    testWidgets('đội chưa có thành viên: vẫn có đúng một ô trống', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeTeamRepository(),
        teamToEdit: _existingTeam(members: const []),
      );

      expect(fields(), findsNWidgets(3));
      expect(_text(tester, 1), '');
    });

    testWidgets(
      'sửa tên rồi lưu: gọi update đúng id, giữ mã QR cũ, không tạo mới',
      (tester) async {
        final repo = _FakeTeamRepository();
        await _pump(tester, repo, teamToEdit: _existingTeam());

        await tester.enterText(fields().at(0), ' Đội Đổi Tên ');
        await save(tester);

        expect(repo.created, isEmpty);
        final update = repo.updated.single;
        expect(update.teamId, 'team-7');
        expect(update.data['name'], 'Đội Đổi Tên');
        expect(update.data['members'], ['An', 'Bình', 'Chi']);
        expect(update.data['contactEmail'], 'doi@example.com');
        expect(update.data['qrCode'], 'VDV_ABC123');
        expect(find.text(l10n.teamAdd_updated), findsOneWidget);
        expect(find.text('MỞ FORM'), findsOneWidget);
      },
    );

    testWidgets('xoá một thành viên rồi lưu: danh sách gửi đi bỏ người đó', (
      tester,
    ) async {
      final repo = _FakeTeamRepository();
      await _pump(tester, repo, teamToEdit: _existingTeam());

      await tester.tap(removeButtons().at(1));
      await tester.pump();
      await save(tester);

      expect(repo.updated.single.data['members'], ['An', 'Chi']);
    });

    testWidgets('xoá hết tên: không cho lưu', (tester) async {
      final repo = _FakeTeamRepository();
      await _pump(tester, repo, teamToEdit: _existingTeam());

      await tester.enterText(fields().at(0), '');
      await save(tester);

      expect(find.text(l10n.teamAdd_nameRequired), findsOneWidget);
      expect(repo.updated, isEmpty);
    });

    testWidgets('giải đang thi đấu: sửa đội bị chặn và báo lỗi', (
      tester,
    ) async {
      final repo = _FakeTeamRepository();
      await _pump(
        tester,
        repo,
        teamToEdit: _existingTeam(),
        tournament: _tournament('in_progress'),
      );

      await tester.enterText(fields().at(0), 'Đổi Muộn');
      await save(tester);

      expect(repo.updated, isEmpty);
      expect(find.text(l10n.teamAdd_error), findsOneWidget);
      expect(find.text(l10n.teamAdd_updated), findsNothing);
    });

    testWidgets('cập nhật lỗi: báo lỗi và vẫn ở form sửa', (tester) async {
      final repo = _FakeTeamRepository()..failWith = StateError('lỗi');
      await _pump(tester, repo, teamToEdit: _existingTeam());

      await save(tester);

      expect(find.text(l10n.teamAdd_error), findsOneWidget);
      expect(find.text(l10n.teamAdd_editTitle), findsOneWidget);
    });
  });
}
