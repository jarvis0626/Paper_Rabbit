import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../papers/data/paper_models.dart';
import '../../papers/data/paper_repository.dart';
import 'library_models.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(dioProvider)),
);

class LibraryRepository {
  const LibraryRepository(this._dio);

  final Dio _dio;

  Future<List<LibraryPaper>> list({
    ReadingStatus? status,
    String? tag,
    String? query,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        '/api/library',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (tag?.trim().isNotEmpty == true) 'tag': tag!.trim(),
          if (query?.trim().isNotEmpty == true) 'q': query!.trim(),
        },
      );
      if (response.data is! List) {
        throw const ApiException('The server returned an unexpected response.');
      }
      return (response.data! as List)
          .whereType<Map>()
          .map((item) => LibraryPaper.fromJson(item.cast<String, dynamic>()))
          .toList();
    } on DioException catch (error) {
      throw _readException(error);
    }
  }

  Future<LibraryPaper?> get(String paperId) async {
    try {
      final response = await _dio.get<Object?>(
        '/api/library/${Uri.encodeComponent(paperId)}',
      );
      return LibraryPaper.fromJson(_asJson(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw _readException(error);
    }
  }

  Future<LibraryPaper> save(PaperDetails paper) async {
    try {
      final response = await _dio.post<Object?>(
        '/api/library',
        data: {
          'paperId': paper.id,
          'title': paper.title,
          'authors': paper.authors.map((author) => author.name).toList(),
          'year': paper.year,
          'venue': paper.venue,
          'citationCount': paper.citationCount,
          'externalUrl': paper.externalUrl,
        },
      );
      return LibraryPaper.fromJson(_asJson(response.data));
    } on DioException catch (error) {
      throw _readException(error);
    }
  }

  Future<LibraryPaper> update(
    String paperId, {
    required ReadingStatus status,
    required String? notes,
    required Iterable<String> tags,
  }) async {
    try {
      final response = await _dio.put<Object?>(
        '/api/library/${Uri.encodeComponent(paperId)}',
        data: {
          'readingStatus': status.apiValue,
          'notes': notes,
          'tags': tags.toList(),
        },
      );
      return LibraryPaper.fromJson(_asJson(response.data));
    } on DioException catch (error) {
      throw _readException(error);
    }
  }

  Future<void> delete(String paperId) async {
    try {
      await _dio.delete<void>('/api/library/${Uri.encodeComponent(paperId)}');
    } on DioException catch (error) {
      throw _readException(error);
    }
  }

  Map<String, dynamic> _asJson(Object? value) {
    if (value is! Map) {
      throw const ApiException('The server returned an unexpected response.');
    }
    return value.cast<String, dynamic>();
  }

  ApiException _readException(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String);
    }
    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        'Cannot reach the Paper Rabbit server. Check that the backend is running.',
      );
    }
    return const ApiException('Paper Rabbit could not update your library.');
  }
}
