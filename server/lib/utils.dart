import 'dart:convert';
import 'dart:io';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:screwdriver/screwdriver.dart';

class LoggerInterceptor extends InterceptorContract {
  static const String _separator =
      '--------------------------------------------------------------------------------';

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    _printSeparator();
    print('REQUEST: ${request.method} ${request.url}');
    _printSeparator();

    if (request.headers.isNotEmpty) {
      print('HEADERS:');
      _printHeaders(request.headers);
    } else {
      print('HEADERS: <empty>');
    }

    _printSeparator();

    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    _printSeparator();
    print(
      'RESPONSE: ${response.statusCode} '
      '${response.request?.method} '
      '${response.request?.url}',
    );
    _printSeparator();

    if (response.headers.isNotEmpty) {
      print('HEADERS:');
      _printHeaders(response.headers);
    } else {
      print('HEADERS: <empty>');
    }

    if (response case Response(:final body)) {
      _printSeparator();
      print('BODY:');

      final contentType =
          response.headers[HttpHeaders.contentTypeHeader];

      if (_isJson(contentType)) {
        final json = tryJsonDecode(body);

        if (json != null) {
          try {
            print(
              const JsonEncoder.withIndent('  ').convert(json),
            );
          } catch (_) {
            print(body);
          }
        } else {
          print(body);
        }
      } else {
        print(body);
      }
    }

    _printSeparator();

    return response;
  }

  void _printSeparator() {
    print(_separator);
  }

  void _printHeaders(Map<String, String> headers) {
    if (headers.isEmpty) {
      print('<empty>');
      return;
    }

    final maxKeyLength = headers.keys
        .map((e) => e.length)
        .fold<int>(0, (prev, curr) => curr > prev ? curr : prev);

    headers.entries
        .sorted((a, b) => a.key.compareTo(b.key))
        .forEach(
          (entry) => print(
            '${entry.key.padRight(maxKeyLength)} : ${entry.value}',
          ),
        );
  }

  bool _isJson(String? contentType) {
    if (contentType == null) {
      return false;
    }

    return contentType.contains('application/json');
  }
}
