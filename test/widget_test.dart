import 'package:flutter_test/flutter_test.dart';
import 'package:susu/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SusuApp());

    // Verify that the login screen title is displayed.
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Login Screen Placeholder'), findsOneWidget);
  });
}
