// This is a basic Flutter widget test for CivicWelfare app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:civic_welfare/main.dart';

void main() {
  testWidgets('CivicWelfare app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the user type selection screen loads
    expect(find.text('Welcome to CivicWelfare'), findsOneWidget);
    expect(find.text('Select Your Role'), findsOneWidget);
    
    // Verify that user type buttons are present
    expect(find.text('Citizen'), findsOneWidget);
    expect(find.text('Officer'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
