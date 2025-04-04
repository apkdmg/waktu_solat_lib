// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

// Import the app's main.dart file
// ignore: avoid_relative_lib_imports
import '../lib/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed
    expect(find.text('Waktu Solat Lib Example'), findsOneWidget);
    
    // Verify that the fetch buttons are present
    expect(find.text('Fetch Zones'), findsOneWidget);
    expect(find.text('Fetch Times (SGR01)'), findsOneWidget);
    expect(find.text('Fetch Times (GPS)'), findsOneWidget);
  });
}
