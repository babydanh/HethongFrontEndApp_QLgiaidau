import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';

void main() {
  test('resolves distinct canonical assets for supported sports', () {
    expect(AppIcons.sportAsset('badminton'), 'assets/icons/badminton.svg');
    expect(AppIcons.sportAsset('Bóng đá'), 'assets/icons/football.svg');
    expect(AppIcons.sportAsset('pickleball'), 'assets/icons/pickleball.png');
    expect(AppIcons.sportAsset('Tennis'), 'assets/icons/tennis.svg');
  });

  test('keeps a safe fallback for unknown sports', () {
    expect(AppIcons.sportAsset('unknown'), isNull);
  });
}
