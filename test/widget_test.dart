import 'package:flutter_test/flutter_test.dart';
import 'package:tiketdotcom/main.dart';

void main() {
  testWidgets('Splash screen shows app title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TicketingApp());

    // Verify that Splash Screen shows the title.
    expect(find.text('E-Ticketing Helpdesk'), findsOneWidget);
  });
}
