// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church/main.dart';
import 'package:church/modules/Auth/login/login_screen.dart';
import 'package:church/core/constants/strings.dart';

void main() {
  testWidgets('Login screen renders and shows login text', (WidgetTester tester) async {
    // Increase test surface to avoid layout overflow in small test viewports.
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    // Build our app with LoginScreen as the start widget and trigger a frame.
    await tester.pumpWidget(MyApp(startWidget: LoginScreen()));

    // Verify that the login text appears at least once on screen.
    expect(find.text(login), findsWidgets);

    // Ensure the ElevatedButton with login text exists
    expect(find.widgetWithText(ElevatedButton, login), findsOneWidget);
  });
}
