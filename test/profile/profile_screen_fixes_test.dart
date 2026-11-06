// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _FakePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(Uint8List(16), name: 'cover.png');
}

class _Users implements IUserRepository {
  @override
  Future<UserProfile> uploadCover(List<int> bytes, String fileName) async =>
      throw Exception('boom raw');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _profile = UserProfile(
  id: 'u1',
  fullName: 'Nguyen An',
  email: 'an@x.com',
  eloPoints: 1500,
);

const _rank = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'Nguyen An',
  eloPoints: 1500,
  tierName: 'Gold',
  matchesPlayed: 10,
  matchesWon: 7,
  categoryName: 'Pickleball',
);

Future<void> _pump(
  WidgetTester tester, {
  UserProfile profile = _profile,
  Future<List<PlayerRanking>> Function()? ranks,
  Future<List<Tournament>> Function()? followed,
  Size size = const Size(800, 1800),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(_FakeAuth.new),
        dioProvider.overrideWithValue(Dio(BaseOptions(baseUrl: 'http://test'))),
        userRepositoryProvider.overrideWithValue(_Users()),
        userProfileProvider.overrideWith((ref) async => profile),
        userRankingsProvider.overrideWith(
          (ref) => ranks != null ? ranks() : Future.value([_rank]),
        ),
        publicUserMatchesProvider.overrideWith(
          (ref, id) async => <MatchModel>[],
        ),
        followedTournamentsProvider.overrideWith(
          (ref) => followed != null ? followed() : Future.value(<Tournament>[]),
        ),
        userFriendsProvider.overrideWith((ref) async => <FriendshipItem>[]),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ProfileScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('giới tính trong dòng meta', () {
    testWidgets('MALE hiện Nam cùng địa chỉ', (tester) async {
      await _pump(
        tester,
        profile: const UserProfile(
          id: 'u1',
          fullName: 'An',
          gender: 'MALE',
          address: 'Hà Nội',
        ),
      );
      expect(find.text('Nam · Hà Nội'), findsOneWidget);
    });

    testWidgets('giá trị lạ không bị coi là Nam', (tester) async {
      await _pump(
        tester,
        profile: const UserProfile(
          id: 'u1',
          fullName: 'An',
          gender: 'weird',
          address: 'Hà Nội',
        ),
      );
      expect(find.text('Hà Nội'), findsOneWidget);
      expect(find.textContaining('Nam'), findsNothing);
    });
  });

  group('thống kê khi lỗi / đang tải', () {
    testWidgets('rankings và followed lỗi hiện — thay vì 0', (tester) async {
      await _pump(
        tester,
        ranks: () async => throw Exception('boom'),
        followed: () async => throw Exception('boom'),
      );
      // Trận, Thắng%, Giải; ELO lấy từ hồ sơ nên vẫn có số.
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('1,500'), findsWidgets);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('đang tải hiện — thay vì 0', (tester) async {
      final never = Completer<List<PlayerRanking>>();
      final neverT = Completer<List<Tournament>>();
      await _pump(
        tester,
        ranks: () => never.future,
        followed: () => neverT.future,
      );
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('có dữ liệu thật vẫn hiện số (0 giải là 0 thật)', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('chạm vào thống kê lỗi thì tải lại', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        ranks: () async {
          calls++;
          throw Exception('boom');
        },
      );
      expect(calls, 1);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileScreen)),
      )!;
      await tester.tap(find.text(l10n.profLvStatMatches));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, 2);
    });
  });

  testWidgets('lỗi tải ảnh bìa hiện thông báo thân thiện, không lộ Exception', (
    tester,
  ) async {
    ImagePickerPlatform.instance = _FakePicker();
    await _pump(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ProfileScreen)),
    )!;
    await tester.tap(find.byTooltip(l10n.profileChangeCover));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.profileChooseFromGallery));
    await tester.pumpAndSettle();

    expect(find.textContaining('boom'), findsNothing);
    expect(find.text(l10n.errorParserFallback), findsOneWidget);
  });

  testWidgets('4 nhãn tab đủ chữ ở 320dp và chữ 1.3x, không ellipsis', (
    tester,
  ) async {
    await _pump(tester, size: const Size(320, 640), textScale: 1.3);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ProfileScreen)),
    )!;
    for (final label in [
      l10n.profLvTabActivity,
      l10n.profLvTabTournaments,
      l10n.profLvTabFriends,
      l10n.profLvTabAchievements,
    ]) {
      final finder = find.descendant(
        of: find.byType(TabBar),
        matching: find.text(label),
      );
      expect(finder, findsOneWidget, reason: label);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      expect(
        tester.widget<Text>(finder).overflow,
        isNot(TextOverflow.ellipsis),
        reason: label,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
