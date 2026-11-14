import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/referee/screens/referee_invites_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTournamentRepository extends Mock implements ITournamentRepository {}

class _SignedInNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.referee);
}

TournamentRefereeInvite _invite({
  String refereeId = 'r1',
  String tournamentId = 't1',
  String name = 'Giải Mùa Hè',
  String category = 'Pickleball',
  String status = 'INVITED',
  DateTime? assignedAt,
}) => TournamentRefereeInvite(
  refereeId: refereeId,
  tournamentId: tournamentId,
  tournamentName: name,
  tournamentStatus: 'REGISTRATION',
  categoryName: category,
  assignedAt: assignedAt,
  status: status,
);

_MockTournamentRepository _repoWith(List<TournamentRefereeInvite> invites) {
  final repo = _MockTournamentRepository();
  when(
    () => repo.getMyWorkspace(
      cursor: any(named: 'cursor'),
      limit: any(named: 'limit'),
      role: any(named: 'role'),
    ),
  ).thenAnswer((_) async => TournamentWorkspace(refereeInvites: invites));
  when(
    () => repo.respondToRefereeInvite(
      tournamentId: any(named: 'tournamentId'),
      refereeId: any(named: 'refereeId'),
      action: any(named: 'action'),
    ),
  ).thenAnswer((_) async {});
  return repo;
}

Future<void> _pump(WidgetTester tester, ITournamentRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      // Riverpod 3 tự thử lại provider lỗi; tắt để thấy ngay màn lỗi.
      retry: (_, _) => null,
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWith(_SignedInNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
        home: const RefereeInvitesScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('chỉ hiện lời mời đang chờ, bỏ lời mời đã nhận hoặc từ chối', (
    tester,
  ) async {
    await _pump(
      tester,
      _repoWith([
        _invite(name: 'Giải Đang Chờ'),
        _invite(name: 'Giải Đã Nhận', refereeId: 'r2', status: 'ACCEPTED'),
        _invite(name: 'Giải Đã Từ Chối', refereeId: 'r3', status: 'DECLINED'),
      ]),
    );

    expect(find.text('Giải Đang Chờ'), findsOneWidget);
    expect(find.text('Giải Đã Nhận'), findsNothing);
    expect(find.text('Giải Đã Từ Chối'), findsNothing);
    expect(find.text('Nhận nhiệm vụ'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
  });

  testWidgets(
    'thẻ mời hiện tên hạng mục, nhãn chờ và báo chưa rõ lịch khi thiếu ngày',
    (tester) async {
      await _pump(tester, _repoWith([_invite()]));

      expect(find.text('Pickleball'), findsOneWidget);
      expect(find.text('Chờ phản hồi'), findsOneWidget);
      expect(find.text('Chưa rõ lịch'), findsOneWidget);
    },
  );

  testWidgets('thiếu tên hạng mục thì dùng nhãn Phân công trọng tài', (
    tester,
  ) async {
    await _pump(tester, _repoWith([_invite(category: '')]));

    expect(find.text('Phân công trọng tài'), findsOneWidget);
  });

  testWidgets(
    'không có lời mời nào thì hiện trạng thái rỗng, không có nút phản hồi',
    (tester) async {
      await _pump(tester, _repoWith([]));

      expect(find.text('Không có lời mời nào'), findsOneWidget);
      expect(find.text('Nhận nhiệm vụ'), findsNothing);
    },
  );

  testWidgets('chỉ còn lời mời đã xử lý cũng hiện trạng thái rỗng', (
    tester,
  ) async {
    await _pump(tester, _repoWith([_invite(status: 'ACCEPTED')]));

    expect(find.text('Không có lời mời nào'), findsOneWidget);
  });

  testWidgets('tải lỗi hiện thông báo lỗi và nút thử lại gọi tải lại', (
    tester,
  ) async {
    final repo = _MockTournamentRepository();
    var calls = 0;
    when(
      () => repo.getMyWorkspace(
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('mất mạng');
      return TournamentWorkspace(
        refereeInvites: [_invite(name: 'Giải Sau Retry')],
      );
    });
    await _pump(tester, repo);
    expect(find.text('Không thể tải lời mời trọng tài'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Giải Sau Retry'), findsOneWidget);
    expect(find.text('Không thể tải lời mời trọng tài'), findsNothing);
  });

  testWidgets('nhận lời mời gọi ACCEPT, và báo đã nhận thành công', (
    tester,
  ) async {
    final repo = _repoWith([_invite()]);
    await _pump(tester, repo);

    await tester.tap(find.text('Nhận nhiệm vụ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    verify(
      () => repo.respondToRefereeInvite(
        tournamentId: 't1',
        refereeId: 'r1',
        action: 'ACCEPT',
      ),
    ).called(1);
    expect(find.text('Đã nhận lời mời trọng tài'), findsOneWidget);
  });

  testWidgets('từ chối lời mời gọi DECLINE và báo đã từ chối', (tester) async {
    final repo = _repoWith([_invite()]);
    await _pump(tester, repo);

    await tester.tap(find.text('Từ chối'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    verify(
      () => repo.respondToRefereeInvite(
        tournamentId: 't1',
        refereeId: 'r1',
        action: 'DECLINE',
      ),
    ).called(1);
    expect(find.text('Đã từ chối lời mời trọng tài'), findsOneWidget);
  });

  testWidgets('phản hồi lỗi thì báo lỗi và vẫn giữ thẻ lời mời', (
    tester,
  ) async {
    final repo = _repoWith([_invite()]);
    when(
      () => repo.respondToRefereeInvite(
        tournamentId: any(named: 'tournamentId'),
        refereeId: any(named: 'refereeId'),
        action: any(named: 'action'),
      ),
    ).thenAnswer((_) async => throw Exception('Giải đã đóng'));
    await _pump(tester, repo);

    await tester.tap(find.text('Nhận nhiệm vụ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Không thể xử lý lời mời: Giải đã đóng'), findsOneWidget);
    expect(find.text('Giải Mùa Hè'), findsOneWidget);
  });
}
