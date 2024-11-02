import 'package:cancellation_token_http/http.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'request_cancellation_server_vm.dart'
    if (dart.library.js_interop) 'request_cancellation_server_web.dart';

/// Tests that the [Client] correctly handles cancellation on the HTTP request
/// methods (e.g. GET, HEAD).
void testRequestCancellation(Client client) async {
  group('request cancellation', () {
    late final String host;
    late final StreamChannel<Object?> httpServerChannel;
    late final Stream<Object?> httpServerBroadcastStream;

    setUpAll(() async {
      httpServerChannel = await startServer();
      httpServerBroadcastStream = httpServerChannel.stream.asBroadcastStream();
      host = 'localhost:${await httpServerBroadcastStream.first}';
    });
    tearDownAll(() => httpServerChannel.sink.add('close'));

    test('send', () async {
      const String path = '/send';
      final token = CancellationToken();
      Future<StreamedResponse> request = client.send(
        Request('GET', Uri.http(host, path)),
        cancellationToken: token,
      );
      // Wait for the request to be received before cancelling the token.
      await httpServerBroadcastStream.where((message) => message == path).first;
      token.cancel();
      // Wait for a cancellation token to be thrown before closing the
      // request on the server.
      await expectLater(
        request,
        throwsA(isA<CancelledException>()),
      );
      expect(token.hasCancellables, isFalse);
      httpServerChannel.sink.add('close:$path');
    });

    test('delete', () async {
      const String path = '/delete';
      final token = CancellationToken();
      Future<Response> request = client.delete(
        Uri.http(host, path),
        cancellationToken: token,
      );
      // Wait for the request to be received before cancelling the token.
      await httpServerBroadcastStream.where((message) => message == path).first;
      token.cancel();
      // Wait for a cancellation token to be thrown before closing the
      // request on the server.
      await expectLater(
        request,
        throwsA(isA<CancelledException>()),
      );
      expect(token.hasCancellables, isFalse);
      httpServerChannel.sink.add('close:$path');
    });

    test('get', () async {
      const String path = '/get';
      final token = CancellationToken();
      Future<Response> request = client.get(
        Uri.http(host, path),
        cancellationToken: token,
      );
      // Wait for the request to be received before cancelling the token.
      await httpServerBroadcastStream.where((message) => message == path).first;
      token.cancel();
      // Wait for a cancellation token to be thrown before closing the
      // request on the server.
      await expectLater(
        request,
        throwsA(isA<CancelledException>()),
      );
      expect(token.hasCancellables, isFalse);
      httpServerChannel.sink.add('close:$path');
    });

    test('head', () async {
      const String path = '/head';
      final token = CancellationToken();
      Future<Response> request = client.head(
        Uri.http(host, path),
        cancellationToken: token,
      );
      // Wait for the request to be received before cancelling the token.
      await httpServerBroadcastStream.where((message) => message == path).first;
      token.cancel();
      // Wait for a cancellation token to be thrown before closing the
      // request on the server.
      await expectLater(
        request,
        throwsA(isA<CancelledException>()),
      );
      expect(token.hasCancellables, isFalse);
      httpServerChannel.sink.add('close:$path');
    });

    test('patch', () async {
      const String path = '/patch';
      final token = CancellationToken();
      Future<Response> request = client.patch(
        Uri.http(host, path),
        cancellationToken: token,
      );
      // Wait for the request to be received before cancelling the token.
      await httpServerBroadcastStream.where((message) => message == path).first;
      token.cancel();
      // Wait for a cancellation token to be thrown before closing the
      // request on the server.
      await expectLater(
        request,
        throwsA(isA<CancelledException>()),
      );
      expect(token.hasCancellables, isFalse);
      httpServerChannel.sink.add('close:$path');
    });

    test('post', () async {
      const String path = '/post';
      final token = CancellationToken();
      Future<Response> request = client.post(
        Uri.http(host, path),
        cancellationToken: token,
      );
      // Wait for the request to be received before cancelling the token.
      await httpServerBroadcastStream.where((message) => message == path).first;
      token.cancel();
      // Wait for a cancellation token to be thrown before closing the
      // request on the server.
      await expectLater(
        request,
        throwsA(isA<CancelledException>()),
      );
      expect(token.hasCancellables, isFalse);
      httpServerChannel.sink.add('close:$path');
    });

    test('put', () async {
      const String path = '/put';
      final token = CancellationToken();
      Future<Response> request = client.put(
        Uri.http(host, path),
        cancellationToken: token,
      );
      // Wait for the request to be received before cancelling the token.
      await httpServerBroadcastStream.where((message) => message == path).first;
      token.cancel();
      // Wait for a cancellation token to be thrown before closing the
      // request on the server.
      await expectLater(
        request,
        throwsA(isA<CancelledException>()),
      );
      expect(token.hasCancellables, isFalse);
      httpServerChannel.sink.add('close:$path');
    });
  });
}
