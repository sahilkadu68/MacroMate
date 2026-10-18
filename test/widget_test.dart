import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/app.dart';
import 'package:macromate_india/core/constants/app_constants.dart';
import 'package:macromate_india/data/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.instance.database;
  });

  testWidgets('MacroMateApp loads and renders 5 navigation destinations', (
    WidgetTester tester,
  ) async {
    // Set viewport for a standard mobile screen
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MacroMateApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify app title & navigation destinations
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Foods'), findsOneWidget);
    expect(find.text('Protein Finder'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap on 'Foods' tab
    await tester.tap(find.text('Foods'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Indian Food Catalogue'), findsOneWidget);

    // Tap on 'Protein Finder' tab
    await tester.tap(find.text('Protein Finder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Find Budget Combinations'), findsOneWidget);

    // Tap on 'Progress' tab
    await tester.tap(find.text('Progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Progress & Analytics'), findsOneWidget);

    // Tap on 'Profile' tab
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Profile & Nutrition Goals'), findsOneWidget);

    // Let sqflite internal lock timers finish
    await tester.pump(const Duration(seconds: 11));
  });
}
