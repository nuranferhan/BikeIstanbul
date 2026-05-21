import 'package:flutter_test/flutter_test.dart';

import 'package:bikeistanbul/main.dart';

void main() {
  testWidgets('BikeIstanbul app renders the dashboard', (tester) async {
    await tester.pumpWidget(const BikeIstanbulApp());

    await tester.pumpAndSettle();

    expect(find.text('BikeIstanbul'), findsWidgets);
  });
}
