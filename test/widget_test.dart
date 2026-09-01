import 'package:flutter_test/flutter_test.dart';
import 'package:tuneflow/main.dart';

void main() {
  testWidgets('TuneFlow loads successfully', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const TuneFlowApp(),
    );

    expect(
      find.text('TuneFlow'),
      findsOneWidget,
    );
  });
}