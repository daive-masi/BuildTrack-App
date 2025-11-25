// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BuildTrack CI test - basic widget', (WidgetTester tester) async {
    // Test un widget simple sans Firebase
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('BuildTrack CI Test'),
          ),
        ),
      ),
    );

    // Vérifie que le texte s'affiche
    expect(find.text('BuildTrack CI Test'), findsOneWidget);
  });

  testWidgets('Button tap test', (WidgetTester tester) async {
    var counter = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => counter++,
              child: const Text('Tap me'),
            ),
          ),
        ),
      ),
    );

    // Tap le bouton
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Vérifie que le callback a été appelé
    expect(counter, 1);
  });
}