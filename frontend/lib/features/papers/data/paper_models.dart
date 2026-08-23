class Author {
  const Author({required this.id, required this.name});

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Unknown author',
  );

  final String id;
  final String name;
}

class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.score,
    this.field,
    this.subfield,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Unknown topic',
    score: (json['score'] as num?)?.toDouble() ?? 0,
    field: json['field'] as String?,
    subfield: json['subfield'] as String?,
  );

  final String id;
  final String name;
  final double score;
  final String? field;
  final String? subfield;
}

class PaperSummary {
  const PaperSummary({
    required this.id,
    required this.title,
    required this.authors,
    required this.citationCount,
    required this.topics,
    required this.openAccess,
    this.year,
    this.venue,
    this.abstractPreview,
    this.doi,
    this.externalUrl,
  });

  factory PaperSummary.fromJson(Map<String, dynamic> json) => PaperSummary(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Untitled paper',
    authors: _objects(json['authors']).map(Author.fromJson).toList(),
    year: (json['year'] as num?)?.toInt(),
    venue: json['venue'] as String?,
    citationCount: (json['citationCount'] as num?)?.toInt() ?? 0,
    abstractPreview: json['abstractPreview'] as String?,
    doi: json['doi'] as String?,
    externalUrl: json['externalUrl'] as String?,
    topics: _objects(json['topics']).map(Topic.fromJson).toList(),
    openAccess: json['openAccess'] as bool? ?? false,
  );

  final String id;
  final String title;
  final List<Author> authors;
  final int? year;
  final String? venue;
  final int citationCount;
  final String? abstractPreview;
  final String? doi;
  final String? externalUrl;
  final List<Topic> topics;
  final bool openAccess;
}

class PaperDetails {
  const PaperDetails({
    required this.id,
    required this.title,
    required this.authors,
    required this.citationCount,
    required this.topics,
    required this.openAccess,
    required this.referenceCount,
    required this.referencedWorkIds,
    required this.relatedWorkIds,
    required this.dataSource,
    this.year,
    this.publicationDate,
    this.venue,
    this.type,
    this.abstractText,
    this.doi,
    this.externalUrl,
    this.pdfUrl,
  });

  factory PaperDetails.fromJson(Map<String, dynamic> json) => PaperDetails(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Untitled paper',
    authors: _objects(json['authors']).map(Author.fromJson).toList(),
    year: (json['year'] as num?)?.toInt(),
    publicationDate: json['publicationDate'] as String?,
    venue: json['venue'] as String?,
    type: json['type'] as String?,
    citationCount: (json['citationCount'] as num?)?.toInt() ?? 0,
    abstractText: json['abstractText'] as String?,
    doi: json['doi'] as String?,
    externalUrl: json['externalUrl'] as String?,
    pdfUrl: json['pdfUrl'] as String?,
    topics: _objects(json['topics']).map(Topic.fromJson).toList(),
    openAccess: json['openAccess'] as bool? ?? false,
    referenceCount: (json['referenceCount'] as num?)?.toInt() ?? 0,
    referencedWorkIds: _strings(json['referencedWorkIds']),
    relatedWorkIds: _strings(json['relatedWorkIds']),
    dataSource: json['dataSource'] as String? ?? 'Unknown',
  );

  final String id;
  final String title;
  final List<Author> authors;
  final int? year;
  final String? publicationDate;
  final String? venue;
  final String? type;
  final int citationCount;
  final String? abstractText;
  final String? doi;
  final String? externalUrl;
  final String? pdfUrl;
  final List<Topic> topics;
  final bool openAccess;
  final int referenceCount;
  final List<String> referencedWorkIds;
  final List<String> relatedWorkIds;
  final String dataSource;
}

class PaperPage {
  const PaperPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
  });

  factory PaperPage.fromJson(Map<String, dynamic> json) => PaperPage(
    items: _objects(json['items']).map(PaperSummary.fromJson).toList(),
    page: (json['page'] as num?)?.toInt() ?? 1,
    pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    hasNext: json['hasNext'] as bool? ?? false,
  );

  final List<PaperSummary> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;
}

List<Map<String, dynamic>> _objects(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
