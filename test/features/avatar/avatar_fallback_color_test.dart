import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'TC-APP-AVATAR-01 RankAvatar không ảnh dùng màu theo tên + chữ cái đầu trắng',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RankAvatar(name: 'Nguyễn Hoàng Phong')),
        ),
      );
      final text = tester.widget<Text>(find.text('N'));
      expect(text.style?.color, Colors.white);
      final colors = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.color);
      expect(colors, contains(avatarFallbackColor('Nguyễn Hoàng Phong')));
    },
  );

  test('TC-APP-AVATAR-02 màu ổn định theo tên, khớp bảng màu Web', () {
    expect(avatarFallbackColor('  an  NGUYỄN '), avatarFallbackColor('an nguyễn'));
    // Web: hash("a") = 97 -> 97 % 8 = 1 -> #c2410c
    expect(avatarFallbackColor('A'), const Color(0xFFC2410C));
    expect(avatarInitials('Nguyễn Hoàng Phong'), 'NP');
    expect(avatarInitials(''), '?');
  });
}
