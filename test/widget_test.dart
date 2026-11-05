import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macromate_india/app.dart';
import 'package:macromate_india/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:macromate_india/features/auth/auth_gate.dart';

void main() {
  testWidgets('pushed pages and dialogs retain account providers', (
    tester,
  ) async {
    final auth = AuthController();
    await tester.pumpWidget(
      AccountScope(
        auth: auth,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (routeContext) => Scaffold(
                      body: TextButton(
                        onPressed: () => showDialog<void>(
                          context: routeContext,
                          builder: (dialogContext) => AlertDialog(
                            content: Text(
                              identical(
                                    dialogContext.read<AuthController>(),
                                    auth,
                                  )
                                  ? 'Dialog connected'
                                  : 'Missing account',
                            ),
                          ),
                        ),
                        child: Text(
                          identical(routeContext.read<AuthController>(), auth)
                              ? 'Page connected'
                              : 'Missing account',
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open page'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    expect(find.text('Page connected'), findsOneWidget);
    await tester.tap(find.text('Page connected'));
    await tester.pumpAndSettle();
    expect(find.text('Dialog connected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
    expect(find.text('Username'), findsOneWidget);
    expect(
      find.textContaining('not backed up or synced online'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
  });
}
