import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/features/admin/widgets/admin_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loading_harness.dart';

void main() {
  testWidgets('AdminListSkeleton lays out at 360x640, 412x915 and 820x1180', (
    tester,
  ) async {
    await expectNoOverflowAtAllSizes(tester, const AdminListSkeleton());
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('kit skeletons wrapped for non-scrolling use do not overflow', (
    tester,
  ) async {
    await expectNoOverflowAtAllSizes(
      tester,
      const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          children: [DetailPageSkeleton(), ListPageSkeleton(itemCount: 6)],
        ),
      ),
    );
  });
}
