// Basic widget test template for the Combat Timer app.
//
// This test ensures that the main widget of the app
// can be built without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the main app file
import 'package:combat_timer/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build the main app widget
    await tester.pumpWidget(const CombatTimerApp());

    // Verify that the app builds and a MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
