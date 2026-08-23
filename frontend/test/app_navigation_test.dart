import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('app opens on home and reaches paper search', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Paper Rabbit'), findsOneWidget);
    expect(find.text('Search academic papers'), findsOneWidget);

    await tester.tap(find.text('Search academic papers'));
    await tester.pumpAndSettle();

    expect(find.text('Discover papers'), findsOneWidget);
    expect(find.text('Start with a question or topic'), findsOneWidget);
  });
}
