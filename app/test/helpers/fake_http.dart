import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A Dio adapter that answers from a handler instead of the network, and
/// records what was sent — the server of the `api_*` tests.
class FakeHttp implements HttpClientAdapter {
  FakeHttp(this.handler);

  ResponseBody Function(RequestOptions request) handler;

  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON answer with [status].
ResponseBody json(int status, [Object? body]) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// The course template's error shape.
ResponseBody error(int status, String code, String message) => json(status, {
  'error': {'code': code, 'message': message},
});

/// No answer at all — what a stopped server or a missing network looks like.
Never unreachable(RequestOptions request) => throw DioException.connectionError(
  requestOptions: request,
  reason: 'Connection refused',
);
