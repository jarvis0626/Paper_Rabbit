import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/papers/data/paper_models.dart';

void main() {
  test('PaperPage maps backend search response', () {
    final page = PaperPage.fromJson({
      'items': [
        {
          'id': 'W123',
          'title': 'A useful paper',
          'authors': [
            {'id': 'A1', 'name': 'Ada Author'},
          ],
          'year': 2026,
          'venue': 'Journal of Tests',
          'citationCount': 42,
          'topics': [
            {'id': 'T1', 'name': 'Testing', 'score': 0.95},
          ],
          'openAccess': true,
        },
      ],
      'page': 1,
      'pageSize': 20,
      'total': 100,
      'hasNext': true,
    });

    expect(page.items.single.id, 'W123');
    expect(page.items.single.authors.single.name, 'Ada Author');
    expect(page.items.single.topics.single.score, 0.95);
    expect(page.total, 100);
    expect(page.hasNext, isTrue);
  });

  test('PaperDetails tolerates missing optional metadata', () {
    final paper = PaperDetails.fromJson({
      'id': 'W9',
      'title': 'Sparse metadata',
      'citationCount': 0,
      'referenceCount': 0,
      'openAccess': false,
      'dataSource': 'OpenAlex',
    });

    expect(paper.authors, isEmpty);
    expect(paper.topics, isEmpty);
    expect(paper.abstractText, isNull);
    expect(paper.dataSource, 'OpenAlex');
  });
}
