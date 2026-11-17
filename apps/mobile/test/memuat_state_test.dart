import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/widgets/ilustrasi_gerak.dart';
import 'package:smart_mobile/core/widgets/state_widgets.dart';

void main() {
  ilustrasiTes();
  testWidgets('MemuatState aman di dalam ListView (halaman Kalender)', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 700,
            child: ListView(children: const [Text('Kalender'), MemuatState()]),
          ),
        ),
      ),
    );
    expect(tester(t), isNull);
    expect(find.byType(MemuatState), findsOneWidget);
  });

  testWidgets('MemuatState aman di kotak 100 dp (checklist)', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [SizedBox(height: 100, child: MemuatState())],
          ),
        ),
      ),
    );
    expect(tester(t), isNull);
  });
}

Object? tester(WidgetTester t) => t.takeException();

void ilustrasiTes() {
  testWidgets('ilustrasi bergerak tergambar tanpa galat pada beberapa waktu', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              JamPasir(),
              Gulungan(),
              LembarTerakhir(),
              MemuatHalaman(),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 450));
    }
    expect(t.takeException(), isNull);
  });
}
