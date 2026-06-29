import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudal_diet/main.dart';

void main() {
  testWidgets('renders main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KudalApp()));

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('통계'), findsOneWidget);
    expect(find.text('쿠달이'), findsOneWidget);
  });
}
