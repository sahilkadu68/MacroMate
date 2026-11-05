import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/app.dart';
import 'package:macromate_india/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows local account entry before opening the tracker', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MacroMateApp(auth: AuthController()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to MacroMate'), findsOneWidget);
    expect(find.text('Email or username'), findsOneWidget);
    expect(
      find.textContaining('not backed up or synced online'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
  });
}
