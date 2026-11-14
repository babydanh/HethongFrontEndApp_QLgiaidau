import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_invites_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCommunityRepo extends Fake implements ICommunityRepository {
  List<CommunityInviteModel> invites;
  Object? respondError;
  final List<(String, String)> responded = [];
  int loads = 0;

  _FakeCommunityRepo(this.invites);

  @override
  Future<List<CommunityInviteModel>> getMyInvites() async {
    loads++;
    return invites;
  }

  @override
  Future<void> respondToInvite(String communityId, String action) async {
    responded.add((communityId, action));
    if (respondError != null) throw respondError!;
    invites = invites.where((i) => i.communityId != communityId).toList();
  }
}

class _FailingThenOk extends _FakeCommunityRepo {
  _FailingThenOk() : super([_pendingB]);

  @override
  Future<List<CommunityInviteModel>> getMyInvites() async {
    if (loads++ == 0) throw Exception('offline');
    return invites;
  }
}

const _pendingA = CommunityInviteModel(
  id: 'i1',
  communityId: 'club-a',
  communityName: 'CLB Cầu lông Quận 7',
  inviterName: 'Minh Anh',
);
const _pendingB = CommunityInviteModel(
  id: 'i2',
  communityId: 'club-b',
  communityName: 'CLB Tennis Thủ Đức',
);
const _accepted = CommunityInviteModel(
  id: 'i3',
  communityId: 'club-c',
  communityName: 'CLB Đã Vào',
  status: 'ACCEPTED',
);

Future<void> _pump(WidgetTester tester, _FakeCommunityRepo repo) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ClubInvitesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state when there are no invites', (
    tester,
  ) async {
    await _pump(tester, _FakeCommunityRepo(const []));
    expect(find.text('Không có lời mời nào'), findsOneWidget);
    expect(find.text('Chấp nhận'), findsNothing);
  });

  testWidgets('lists only PENDING invites with inviter and both actions', (
    tester,
  ) async {
    await _pump(tester, _FakeCommunityRepo([_pendingA, _pendingB, _accepted]));
    expect(find.text('CLB Cầu lông Quận 7'), findsOneWidget);
    expect(find.text('CLB Tennis Thủ Đức'), findsOneWidget);
    expect(find.text('CLB Đã Vào'), findsNothing);
    expect(find.text('Được mời bởi Minh Anh'), findsOneWidget);
    expect(find.text('Chấp nhận'), findsNWidgets(2));
    expect(find.text('Từ chối'), findsNWidgets(2));
  });

  testWidgets('shows only the empty state when every invite was handled', (
    tester,
  ) async {
    await _pump(tester, _FakeCommunityRepo([_accepted]));
    expect(find.text('Không có lời mời nào'), findsOneWidget);
  });

  testWidgets('accept calls the repository, reloads and confirms', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo([_pendingA, _pendingB]);
    await _pump(tester, repo);
    await tester.tap(find.text('Chấp nhận').first);
    await tester.pumpAndSettle();

    expect(repo.responded, [('club-a', 'accept')]);
    expect(find.text('Đã chấp nhận lời mời!'), findsOneWidget);
    expect(find.text('CLB Cầu lông Quận 7'), findsNothing);
    expect(find.text('CLB Tennis Thủ Đức'), findsOneWidget);
    expect(repo.loads, 2);
  });

  testWidgets('decline calls the repository with decline and confirms', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo([_pendingB]);
    await _pump(tester, repo);
    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();

    expect(repo.responded, [('club-b', 'decline')]);
    expect(find.text('Đã từ chối lời mời.'), findsOneWidget);
    expect(find.text('Không có lời mời nào'), findsOneWidget);
  });

  testWidgets('accepting an already-handled invite says user is a member', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo([_pendingA])
      ..respondError = Exception('No pending invite');
    await _pump(tester, repo);
    await tester.tap(find.text('Chấp nhận'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn đã là thành viên của câu lạc bộ này.'),
      findsOneWidget,
    );
    expect(find.textContaining('Lỗi xử lý lời mời.'), findsNothing);
  });

  testWidgets('a failed accept shows the error and keeps the invite', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo([_pendingA])
      ..respondError = Exception('Máy chủ bận');
    await _pump(tester, repo);
    await tester.tap(find.text('Chấp nhận'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Lỗi xử lý lời mời. Máy chủ bận'),
      findsOneWidget,
    );
    expect(find.text('CLB Cầu lông Quận 7'), findsOneWidget);
  });

  testWidgets('a failed decline never shows the already-member message', (
    tester,
  ) async {
    final repo = _FakeCommunityRepo([_pendingA])
      ..respondError = Exception('already handled');
    await _pump(tester, repo);
    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn đã là thành viên của câu lạc bộ này.'), findsNothing);
    expect(find.textContaining('Lỗi xử lý lời mời.'), findsOneWidget);
  });

  testWidgets('load error shows retry that loads again', (tester) async {
    final repo = _FailingThenOk();
    await _pump(tester, repo);
    expect(find.text('Không thể tải lời mời'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('CLB Tennis Thủ Đức'), findsOneWidget);
    expect(find.text('Không thể tải lời mời'), findsNothing);
  });
}
