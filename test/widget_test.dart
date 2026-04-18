import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:financial_detective/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FinancialDetectiveApp()),
    );
    await tester.pumpAndSettle();

    // Verify the login screen renders
    expect(find.text('Financial Detective'), findsWidgets);
  });
}
