import 'package:app_quanly_giaidau/domain/services/manage_role_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManageRole.fromApi', () {
    test('TC-REF-MODE-APP-01 missing or MANAGER value means manager', () {
      expect(ManageRole.fromApi(null), ManageRole.manager);
      expect(ManageRole.fromApi(''), ManageRole.manager);
      expect(ManageRole.fromApi('MANAGER'), ManageRole.manager);
      expect(ManageRole.fromApi('manager'), ManageRole.manager);
    });

    test('TC-REF-MODE-APP-02 REFEREE and unknown values fail closed', () {
      expect(ManageRole.fromApi('REFEREE'), ManageRole.referee);
      expect(ManageRole.fromApi(' referee '), ManageRole.referee);
      expect(ManageRole.fromApi('VIEWER'), ManageRole.referee);
      expect(ManageRole.fromApi(42), ManageRole.referee);
    });
  });

  test('TC-REF-MODE-APP-03 referee sees the six operating tabs in order', () {
    expect(visibleHubTabs(ManageRole.referee), const [
      ManageHubTab.overview,
      ManageHubTab.divisions,
      ManageHubTab.athletes,
      ManageHubTab.bracket,
      ManageHubTab.schedule,
      ManageHubTab.results,
    ]);
    expect(visibleHubTabs(ManageRole.manager), ManageHubTab.values);
  });

  test('TC-REF-MODE-APP-04 referee may only move slots and score', () {
    const allowed = {ManageAction.moveMatchSlot, ManageAction.scoreOpenMatch};
    for (final action in ManageAction.values) {
      expect(
        canManageAction(ManageRole.referee, action),
        allowed.contains(action),
        reason: action.name,
      );
      expect(canManageAction(ManageRole.manager, action), isTrue);
    }
  });
}
