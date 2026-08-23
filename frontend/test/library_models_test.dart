import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/library/data/library_models.dart';

void main() {
  test('LibraryPaper maps workflow metadata', () {
    final paper = LibraryPaper.fromJson({
      'id': 'local-id',
      'paperId': 'W123',
      'title': 'Saved research',
      'authors': ['Ada Author'],
      'citationCount': 9,
      'readingStatus': 'READING',
      'notes': 'Review the methods.',
      'tags': ['graph', 'priority'],
      'savedAt': '2026-08-23T10:00:00Z',
      'updatedAt': '2026-08-23T11:00:00Z',
    });

    expect(paper.readingStatus, ReadingStatus.reading);
    expect(paper.authors, ['Ada Author']);
    expect(paper.tags, ['graph', 'priority']);
    expect(paper.updatedAt.isAfter(paper.savedAt), isTrue);
  });
}
