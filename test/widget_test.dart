// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:fittrack_app/fittrack_app.dart';

void main() {
  testWidgets('muestra la base de FITTRACK y el chat contextual', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitTrackApp());

    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Regístrate'), findsOneWidget);
  });
}
