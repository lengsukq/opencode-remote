import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_remote/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCodeRemote());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
