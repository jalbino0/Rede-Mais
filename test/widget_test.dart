import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rede_mais/screens/login_screen.dart';

void main() {
  testWidgets(
    'Rede+ app smoke test',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );

      expect(
        find.text('Rede+'),
        findsOneWidget,
      );

      expect(
        find.text('Entrar na sua conta'),
        findsOneWidget,
      );

      expect(
        find.text('Esqueci minha senha'),
        findsOneWidget,
      );
    },
  );
}