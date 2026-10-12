import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlgd_edu/data/report_service.dart';
import 'package:qlgd_edu/widgets/common.dart';
import 'package:qlgd_edu/widgets/sort_filter_header.dart';

void main() {
  testWidgets('tiêu đề cột: bấm để sắp xếp, menu lọc giá trị', (tester) async {
    var order = ReportOrder.byCode;
    Set<String>? filtered;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Row(children: [
            // Cột hẹp nhất có bộ lọc trên màn Sinh viên.
            SizedBox(
              width: 108,
              child: SortFilterHeader(
                label: 'Khóa',
                column: ReportColumn.cohort,
                order: order,
                onSort: (o) => setState(() => order = o),
                filterValues: const ['QH-2023', 'QH-2024', 'QH-2025'],
                filterSelected: filtered ?? const {},
                onFilter: (s) => setState(() => filtered = s),
              ),
            ),
          ]),
        ),
      ),
    ));

    // Bấm tên cột: sắp xếp tăng dần, bấm lại: giảm dần.
    await tester.tap(find.text('Khóa'));
    await tester.pump();
    expect(order.column, ReportColumn.cohort);
    expect(order.ascending, isTrue);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    await tester.tap(find.text('Khóa'));
    await tester.pump();
    expect(order.ascending, isFalse);

    // Menu ▾ → Sắp xếp A → Z.
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sắp xếp A → Z'));
    await tester.pumpAndSettle();
    expect(order.ascending, isTrue);

    // Menu ▾ → Lọc giá trị… → bỏ chọn QH-2023 → Đồng ý.
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lọc giá trị…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QH-2023'));
    await tester.pump();
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();
    expect(filtered, {'QH-2024', 'QH-2025'});
    expect(find.byIcon(Icons.filter_alt), findsOneWidget); // biểu tượng đang lọc
  });

  testWidgets('cột rất hẹp (cửa sổ macOS nhỏ) không tràn', (tester) async {
    for (final w in [20.0, 40.0, 60.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Row(children: [
            SizedBox(
              width: w,
              child: SortFilterHeader(
                label: 'TC tích lũy',
                column: ReportColumn.passed,
                order: const ReportOrder(ReportColumn.passed, ascending: true),
                onSort: (_) {},
              ),
            ),
          ]),
        ),
      ));
      expect(tester.takeException(), isNull, reason: 'rộng $w');
    }
  });

  testWidgets('bảng hẹp hơn minWidth thì cuộn ngang, không tràn',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: HorizontalOverflow(
            minWidth: 900,
            child: Row(children: [
              for (var i = 0; i < 9; i++)
                const SizedBox(width: 100, child: Text('Cột')),
            ]),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
