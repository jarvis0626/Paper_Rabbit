import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bookmarks_screen.dart';
import 'package:frontend/features/papers/data/paper_repository.dart';

void main() {
  testWidgets('research library explains the empty state', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://paper-rabbit.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<List<Object?>>(requestOptions: options, data: const []),
          );
        },
      ),
    );
    addTearDown(dio.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(home: BookmarksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Research library'), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.text('Find papers'), findsOneWidget);
  });
}
