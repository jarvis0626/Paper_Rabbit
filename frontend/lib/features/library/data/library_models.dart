enum ReadingStatus {
  toRead('TO_READ', 'To read'),
  reading('READING', 'Reading'),
  read('READ', 'Read');

  const ReadingStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReadingStatus fromJson(Object? value) => switch (value) {
    'READING' => reading,
    'READ' => read,
    _ => toRead,
  };
}

class LibraryPaper {
  const LibraryPaper({
    required this.id,
    required this.paperId,
    required this.title,
    required this.authors,
    required this.citationCount,
    required this.readingStatus,
    required this.tags,
    required this.savedAt,
    required this.updatedAt,
    this.year,
    this.venue,
    this.externalUrl,
    this.notes,
  });

  factory LibraryPaper.fromJson(Map<String, dynamic> json) => LibraryPaper(
    id: json['id'] as String? ?? '',
    paperId: json['paperId'] as String? ?? '',
    title: json['title'] as String? ?? 'Untitled paper',
    authors: _strings(json['authors']),
    year: (json['year'] as num?)?.toInt(),
    venue: json['venue'] as String?,
    citationCount: (json['citationCount'] as num?)?.toInt() ?? 0,
    externalUrl: json['externalUrl'] as String?,
    readingStatus: ReadingStatus.fromJson(json['readingStatus']),
    notes: json['notes'] as String?,
    tags: _strings(json['tags']),
    savedAt:
        DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime(1970),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime(1970),
  );

  final String id;
  final String paperId;
  final String title;
  final List<String> authors;
  final int? year;
  final String? venue;
  final int citationCount;
  final String? externalUrl;
  final ReadingStatus readingStatus;
  final String? notes;
  final List<String> tags;
  final DateTime savedAt;
  final DateTime updatedAt;
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
