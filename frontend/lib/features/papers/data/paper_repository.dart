import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/api_exception.dart';
import 'paper_models.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final paperRepositoryProvider = Provider<PaperRepository>(
  (ref) => PaperRepository(ref.watch(dioProvider)),
);

enum SearchMode {
  keyword('keyword', 'Keyword'),
  semantic('semantic', 'Semantic');

  const SearchMode(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class PaperRepository {
  const PaperRepository(this._dio);
  final Dio _dio;

  Future<PaperPage> search({
    required String query,
    required SearchMode mode,
    int page = 1,
    int pageSize = 20,
  }) async => PaperPage.fromJson(
    await _getJson(
      '/api/papers/search',
      queryParameters: {
        'q': query,
        'mode': mode.apiValue,
        'page': page,
        'pageSize': pageSize,
      },
    ),
  );

  Future<PaperDetails> getPaper(String paperId) async => PaperDetails.fromJson(
    await _getJson('/api/papers/${Uri.encodeComponent(paperId)}'),
  );

  Future<List<PaperSummary>> getRelated(String paperId, {int limit = 8}) async {
    final data = await _getList(
      '/api/papers/${Uri.encodeComponent(paperId)}/related',
      queryParameters: {'limit': limit},
    );
    return data.map(PaperSummary.fromJson).toList();
  }

  Future<PaperPage> getReferences(String paperId) async => PaperPage.fromJson(
    await _getJson(
      '/api/papers/${Uri.encodeComponent(paperId)}/references',
      queryParameters: {'pageSize': 10},
    ),
  );

  Future<PaperPage> getCitations(String paperId) async => PaperPage.fromJson(
    await _getJson(
      '/api/papers/${Uri.encodeComponent(paperId)}/citations',
      queryParameters: {'pageSize': 10},
    ),
  );

  Future<CitationGraph> getCitationGraph(
    String paperId, {
    int references = 12,
    int citations = 12,
  }) async => CitationGraph.fromJson(
    await _getJson(
      '/api/papers/${Uri.encodeComponent(paperId)}/graph',
      queryParameters: {'references': references, 'citations': citations},
    ),
  );

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      if (response.data is! Map) {
        throw const ApiException('The server returned an unexpected response.');
      }
      return (response.data! as Map).cast<String, dynamic>();
    } on DioException catch (error) {
      throw _readException(error);
    }
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      if (response.data is! List) {
        throw const ApiException('The server returned an unexpected response.');
      }
      return (response.data! as List)
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    } on DioException catch (error) {
      throw _readException(error);
    }
  }

  ApiException _readException(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException('The request timed out. Please try again.');
    }
    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        'Cannot reach the Paper Rabbit server. Check that the backend is running.',
      );
    }
    return const ApiException('Paper Rabbit could not complete that request.');
  }
}
