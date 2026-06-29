import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApiClient {
  ApiClient({required AppConfig config}) {
    _dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    if (config.isLoggingEnabled) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ));
    }

    // 요청/응답 시간 로그
    if (config.isLoggingEnabled) {
      _dio.interceptors.add(_TimingInterceptor());
    }
  }

  late final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParams);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await _dio.post(path, data: body);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final res = await _dio.patch(
        path,
        data: body,
        queryParameters: queryParams,
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<void> delete(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      await _dio.delete(path, queryParameters: queryParams);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required File file,
    required Map<String, String> fields,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...fields,
        'file': await MultipartFile.fromFile(file.path),
      });
      final res = await _dio.post(
        path,
        data: formData,
        options: Options(
          // multipart 업로드는 시간이 더 필요
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Exception _toException(DioException e) {
    debugPrint('[API ERROR] ${e.type}: ${e.message} | status=${e.response?.statusCode}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('연결이 느려요. 다시 시도해볼까요?');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('서버에 연결할 수 없어요. 인터넷을 확인해주세요.');
    }
    return switch (e.response?.statusCode) {
      400 => Exception('요청이 올바르지 않아요.'),
      404 => Exception('데이터를 찾을 수 없어요.'),
      413 => Exception('이미지 용량이 너무 커요 (5MB 이하).'),
      422 => Exception('분석에 실패했어요. 다시 시도해볼까요?'),
      429 => Exception('잠시 후 다시 시도해주세요.'),
      500 => Exception('서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.'),
      _ => Exception('오류가 발생했어요. 다시 시도해볼까요?'),
    };
  }
}

class _TimingInterceptor extends Interceptor {
  final _startTimes = <int, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _startTimes[options.hashCode] = DateTime.now();
    debugPrint('[API] → ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = _startTimes.remove(response.requestOptions.hashCode);
    final ms = start != null
        ? DateTime.now().difference(start).inMilliseconds
        : -1;
    debugPrint(
      '[API] ← ${response.statusCode} ${response.requestOptions.path} (${ms}ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _startTimes.remove(err.requestOptions.hashCode);
    debugPrint(
      '[API] ✗ ${err.requestOptions.method} ${err.requestOptions.path} → ${err.type}',
    );
    handler.next(err);
  }
}
