import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_accordion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// gon-danh-sach-doi 1.1: the participant count sits in one fixed column no
// matter how long the division name is.
void main() {
  testWidgets('participant counts share one right edge; long names ellipsize', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longName = 'Đôi Nam Nữ Linh Hoạt Trên Năm Mươi Tuổi Toàn Quốc Mở Rộng';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DivisionAccordion(
            divisions: const [
              TournamentDivision(
                id: 'short',
                name: 'Đơn',
                matchType: 'SINGLES',
                maxParticipants: 16,
                participantCount: 3,
              ),
              TournamentDivision(
                id: 'long',
                name: longName,
                matchType: 'DOUBLES',
                maxParticipants: 16,
                participantCount: 9,
              ),
              TournamentDivision(
                id: 'open',
                name: 'Mở',
                matchType: 'SINGLES',
                participantCount: 12,
              ),
            ],
            selectedDivisionId: 'short',
            expanded: false,
            onTapDivision: (_) {},
          ),
        ),
      ),
    );

    final shortRight = tester.getTopRight(find.text('3/16')).dx;
    final longRight = tester.getTopRight(find.text('9/16')).dx;
    final openRight = tester.getTopRight(find.text('12')).dx;
    expect(longRight, shortRight);
    expect(openRight, shortRight);

    final longText = tester.widget<Text>(find.text(longName));
    expect(longText.overflow, TextOverflow.ellipsis);
    expect(longText.maxLines, 1);
    expect(tester.takeException(), isNull);
  });
}
