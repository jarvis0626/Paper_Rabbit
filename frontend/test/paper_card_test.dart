import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/papers/data/paper_models.dart';
import 'package:frontend/features/papers/presentation/paper_card.dart';

void main() {
  testWidgets('PaperCard renders metadata and handles selection', (
    tester,
  ) async {
    var selected = false;
    const paper = PaperSummary(
      id: 'W1',
      title: 'Reliable Research Interfaces',
      authors: [Author(id: 'A1', name: 'Grace Researcher')],
      year: 2025,
      venue: 'UI Science',
      citationCount: 17,
      abstractPreview: 'An abstract preview.',
      topics: [Topic(id: 'T1', name: 'Interfaces', score: 0.8)],
      openAccess: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaperCard(paper: paper, onTap: () => selected = true),
        ),
      ),
    );

    expect(find.text('Reliable Research Interfaces'), findsOneWidget);
    expect(find.text('Grace Researcher'), findsOneWidget);
    expect(find.text('17 citations'), findsOneWidget);
    expect(find.text('Open access'), findsOneWidget);
    await tester.tap(find.text('Reliable Research Interfaces'));
    expect(selected, isTrue);
  });
}
