import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qlgd_edu/widgets/version_badge.dart';

void main() {
  testWidgets('hiện phiên bản ứng dụng', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'QLGD EDU',
      packageName: 'edu.vnu.qlgd',
      version: '1.2.3',
      buildNumber: '9',
      buildSignature: '',
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: VersionBadge()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Phiên bản 1.2.3'), findsOneWidget);
  });
}
