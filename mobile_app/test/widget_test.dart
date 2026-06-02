// Basic smoke test for the Bullet Detection System app.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BulletDetectionApp());

    // Verify the login screen is displayed
    expect(find.text('BULLET DETECTION'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
