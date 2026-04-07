import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/app/app.dart';

void main() {
  testWidgets('App boot test - app can launch', (WidgetTester tester) async {
    await tester.pumpWidget(const MeowApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
