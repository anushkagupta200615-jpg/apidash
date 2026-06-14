import 'dart:io';
import 'package:better_networking/consts.dart';
import 'package:better_networking/models/http_request_model.dart';
import 'package:better_networking/services/http_service.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late String serverUrl;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    serverUrl = 'http://localhost:${server.port}/sse';

    server.listen((HttpRequest request) {
      if (request.uri.path == '/sse') {
        request.response.headers.contentType = ContentType('text', 'event-stream');
        request.response.headers.set('Cache-Control', 'no-cache');
        request.response.headers.set('Connection', 'keep-alive');

        request.response.write('data: event1\n\n');
        request.response.flush();

        Future.delayed(const Duration(seconds: 1), () {
          try {
            request.response.write('data: event2\n\n');
            request.response.flush();
          } catch (_) {}
        });
        Future.delayed(const Duration(seconds: 2), () {
          try {
            request.response.write('data: event3\n\n');
            request.response.close();
          } catch (_) {}
        });
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.close();
      }
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  group('streamHttpRequest: SSE Specific Tests', () {
    test(
      'SSE Stream - Should receive at least two events in 4 seconds',
      () async {
        final model = HttpRequestModel(
          url: serverUrl,
          method: HTTPVerb.get,
        );

        final stream = await streamHttpRequest('sse_test', APIType.rest, model);

        final outputs = <HttpStreamOutput?>[];
        final subscription = stream.listen(outputs.add);

        await Future.delayed(const Duration(seconds: 4));
        await subscription.cancel();

        final eventCount = outputs.where((e) => e?.$1 == true).length;
        expect(
          eventCount,
          greaterThanOrEqualTo(2),
          reason: 'Output -> $outputs',
        );
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );

    test(
      'SSE Stream - Cancellation should work',
      () async {
        final model = HttpRequestModel(
          url: serverUrl,
          method: HTTPVerb.get,
        );

        final stream = await streamHttpRequest('sse_test_c', APIType.rest, model);
        final outputs = <HttpStreamOutput?>[];
        final subscription = stream.listen(outputs.add);

        await Future.delayed(const Duration(seconds: 1));
        httpClientManager.cancelRequest('sse_test_c');
        await Future.delayed(const Duration(milliseconds: 300));
        await subscription.cancel();

        final errMsg = outputs.lastOrNull?.$4;
        expect(errMsg, 'Request Cancelled');
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );
  });
}
