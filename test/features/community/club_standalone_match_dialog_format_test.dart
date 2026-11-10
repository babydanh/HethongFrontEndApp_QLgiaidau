import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_dialog.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_bracket_form.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CommunityMemberModel _member(String id, String name) => CommunityMemberModel(
  id: 'm-$id',
  userId: id,
  communityId: '',
  userFullName: name,
);

final _members = [
  _member('u1', 'An'),
  _member('u2', 'Bình'),
  _member('u3', 'Chi'),
  _member('u4', 'Dũng'),
];

Future<void> _pump(WidgetTester tester, {required bool allowBracket}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ClubStandaloneMatchDialog(
            socialSessionId: 's1',
            preselectedMembers: _members,
            allowBracket: allowBracket,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _createEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

void main() {
  testWidgets('TC-SOCIAL-BRACKET-APP-09: mặc định Đôi (2 mỗi đội), không có Thể thức khi không được phép', (
    tester,
  ) async {
    await _pump(tester, allowBracket: false);

    expect(find.text('0/2'), findsNWidgets(2));
    expect(find.text('Bracket'), findsNothing);
    final segments = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    expect(segments.selected, {'DOUBLES'});
  });

  testWidgets('TC-SOCIAL-BRACKET-APP-10: chọn Đơn thì mỗi đội đúng 1 người mới tạo được', (
    tester,
  ) async {
    await _pump(tester, allowBracket: false);

    await tester.tap(find.text('Đơn'));
    await tester.pumpAndSettle();
    expect(find.text('0/1'), findsNWidgets(2));
    expect(_createEnabled(tester), isFalse);

    await tester.tap(find.text('An'));
    await tester.tap(find.text('Bình'));
    await tester.pumpAndSettle();
    expect(find.text('1/1'), findsNWidgets(2));
    expect(_createEnabled(tester), isTrue);

    // Switching back to doubles clears both sides.
    await tester.tap(find.text('Đôi'));
    await tester.pumpAndSettle();
    expect(find.text('0/2'), findsNWidgets(2));
    expect(_createEnabled(tester), isFalse);
  });

  testWidgets('TC-SOCIAL-BRACKET-APP-11: allowBracket hiện Thể thức; chọn Bracket thay danh sách đội bằng form', (
    tester,
  ) async {
    await _pump(tester, allowBracket: true);

    expect(find.text('Một trận'), findsOneWidget);
    expect(find.byType(SocialBracketForm), findsNothing);

    await tester.tap(find.text('Bracket'));
    await tester.pumpAndSettle();

    expect(find.byType(SocialBracketForm), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Tạo bracket'), findsOneWidget);
    expect(find.text('Đội A'), findsNothing);
  });
}
