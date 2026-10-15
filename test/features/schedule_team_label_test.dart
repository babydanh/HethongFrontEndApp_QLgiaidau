import 'package:app_quanly_giaidau/features/tournament/utils/schedule_team_label.dart';
import 'package:flutter_test/flutter_test.dart';

// Cùng quy tắc `formatCompetitorDisplay` của lịch web (PublicCourtScheduleBoard).
void main() {
  test('single player keeps the last two words', () {
    expect(scheduleShortTeamName('Nguyễn Văn An'), 'Văn An');
    expect(scheduleShortTeamName('Trịnh Quang'), 'Trịnh Quang');
  });

  test('pair name is split and each player shortened', () {
    expect(
      scheduleShortTeamName('QA Bổ sung 15 - QA Bổ sung 16'),
      'sung 15 / sung 16',
    );
    expect(
      scheduleShortTeamName('Nguyễn Văn An / Lê Thị Bình'),
      'Văn An / Thị Bình',
    );
  });

  test('roster members win over the joined team name', () {
    expect(
      scheduleShortTeamName(
        'Đội lạ',
        members: const ['Phan Thảo Vy', 'Hà Thảo Nguyên'],
      ),
      'Thảo Vy / Thảo Nguyên',
    );
  });

  test('placeholder names stay readable', () {
    expect(scheduleShortTeamName('TBD'), 'TBD');
    expect(scheduleShortTeamName('  '), '');
  });
}
