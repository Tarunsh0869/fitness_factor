import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_factor/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FitnessFactorApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
