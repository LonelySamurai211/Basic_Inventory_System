// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cocool_hotel_flutter/src/app.dart';

void main() {
  testWidgets('App loads dashboard shell', (tester) async {
    await tester.pumpWidget(const CocoolHotelApp());
    await tester.pumpAndSettle();

    // Verify the app loads the dashboard page
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
