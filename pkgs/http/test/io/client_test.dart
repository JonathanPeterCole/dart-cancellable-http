// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:cancellation_token_http/http.dart' as http;
import 'package:cancellation_token_http/io_client.dart' as http_io;
import 'package:test/test.dart';

import '../utils.dart';

class TestClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request, {
    CancellationToken? cancellationToken,
  }) {
    throw UnimplementedError();
  }
}

class TestClient2 extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request, {
    CancellationToken? cancellationToken,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  late Uri serverUrl;
  setUpAll(() async {
    serverUrl = await startServer();
  });

  test('#send a StreamedRequest', () async {
    var client = http.Client();
    var request = http.StreamedRequest('POST', serverUrl)
      ..headers[HttpHeaders.contentTypeHeader] =
          'application/json; charset=utf-8'
      ..headers[HttpHeaders.userAgentHeader] = 'Dart';

    var responseFuture = client.send(request);
    request.sink.add('{"hello": "world"}'.codeUnits);
    unawaited(request.sink.close());

    var response = await responseFuture;

    expect(response.request, equals(request));
    expect(response.statusCode, equals(200));
    expect(response.headers['single'], equals('value'));
    // dart:io internally normalizes outgoing headers so that they never
    // have multiple headers with the same name, so there's no way to test
    // whether we handle that case correctly.

    var bytesString = await response.stream.bytesToString();
    client.close();
    expect(
        bytesString,
        parse(equals({
          'method': 'POST',
          'path': '/',
          'headers': {
            'content-type': ['application/json; charset=utf-8'],
            'accept-encoding': ['gzip'],
            'user-agent': ['Dart'],
            'transfer-encoding': ['chunked']
          },
          'body': '{"hello": "world"}'
        })));
  });

  test('#send a StreamedRequest with a custom client', () async {
    var ioClient = HttpClient();
    var client = http_io.IOClient(ioClient);
    var request = http.StreamedRequest('POST', serverUrl)
      ..headers[HttpHeaders.contentTypeHeader] =
          'application/json; charset=utf-8'
      ..headers[HttpHeaders.userAgentHeader] = 'Dart';

    var responseFuture = client.send(request);
    request.sink.add('{"hello": "world"}'.codeUnits);
    unawaited(request.sink.close());

    var response = await responseFuture;

    expect(response.request, equals(request));
    expect(response.statusCode, equals(200));
    expect(response.headers['single'], equals('value'));
    // dart:io internally normalizes outgoing headers so that they never
    // have multiple headers with the same name, so there's no way to test
    // whether we handle that case correctly.

    var bytesString = await response.stream.bytesToString();
    client.close();
    expect(
        bytesString,
        parse(equals({
          'method': 'POST',
          'path': '/',
          'headers': {
            'content-type': ['application/json; charset=utf-8'],
            'accept-encoding': ['gzip'],
            'user-agent': ['Dart'],
            'transfer-encoding': ['chunked']
          },
          'body': '{"hello": "world"}'
        })));
  });

  test('#send with an invalid URL', () {
    var client = http.Client();
    var url = Uri.http('http.invalid', '');
    var request = http.StreamedRequest('POST', url);
    request.headers[HttpHeaders.contentTypeHeader] =
        'application/json; charset=utf-8';

    expect(
        client.send(request),
        throwsA(allOf(
            isA<http.ClientException>().having((e) => e.uri, 'uri', url),
            isA<SocketException>().having(
                (e) => e.toString(),
                'SocketException.toString',
                matches('ClientException with SocketException.*,'
                    ' uri=http://http.invalid')))));

    request.sink.add('{"hello": "world"}'.codeUnits);
    request.sink.close();
  });

  test('send a StreamedRequest with cancellation whilst connecting', () async {
    final token = CancellationToken();
    var client = http.Client();
    var request = http.StreamedRequest('POST', serverUrl.resolve('/delayed'))
      ..headers[HttpHeaders.contentTypeHeader] =
          'application/json; charset=utf-8'
      ..headers[HttpHeaders.userAgentHeader] = 'Dart'
      ..sink.add('{"hello": "world"}'.codeUnits)
      ..sink.close();

    Future.delayed(const Duration(seconds: 1), token.cancel);

    await expectLater(
      client.send(request, cancellationToken: token),
      throwsA(isA<CancelledException>()),
    );
    expect(token.hasCancellables, isFalse);
  });

  test(
      'send a StreamedRequest with cancellation whilst sending the request '
      'body', () async {
    final token = CancellationToken();
    var client = http.Client();
    var request = http.StreamedRequest('POST', serverUrl)
      ..headers[HttpHeaders.contentTypeHeader] =
          'application/json; charset=utf-8'
      ..headers[HttpHeaders.userAgentHeader] = 'Dart'
      ..contentLength = 10
      ..sink.add([1, 2, 3, 4, 5]);

    Future.delayed(const Duration(seconds: 1), token.cancel);

    await expectLater(
      client.send(request, cancellationToken: token),
      throwsA(isA<CancelledException>()),
    );
    expect(token.hasCancellables, isFalse);
  });

  test(
      'send a StreamedRequest with cancellation whilst receiving the response '
      'body', () async {
    final token = CancellationToken();
    var client = http.Client();
    var request =
        http.StreamedRequest('POST', serverUrl.resolve('/delayed-close'))
          ..headers[HttpHeaders.contentTypeHeader] =
              'application/json; charset=utf-8'
          ..headers[HttpHeaders.userAgentHeader] = 'Dart'
          ..sink.add('{"hello": "world"}'.codeUnits)
          ..sink.close();

    Future.delayed(const Duration(seconds: 1), token.cancel);

    await expectLater(
      (await client.send(request, cancellationToken: token)).stream,
      emitsError(isA<CancelledException>()),
    );
    expect(token.hasCancellables, isFalse);
  });

  test('sends a MultipartRequest with correct content-type header', () async {
    var client = http.Client();
    var request = http.MultipartRequest('POST', serverUrl);

    var response = await client.send(request);

    var bytesString = await response.stream.bytesToString();
    client.close();

    var headers = (jsonDecode(bytesString) as Map<String, dynamic>)['headers']
        as Map<String, dynamic>;
    var contentType = (headers['content-type'] as List).single;
    expect(contentType, startsWith('multipart/form-data; boundary='));
  });

  test(
      'cancelling a request does not affect other requests using the same '
      'underlying client', () async {
    var ioClient = HttpClient();
    var client = http_io.IOClient(ioClient);
    var token = CancellationToken();

    Future.delayed(const Duration(seconds: 1), token.cancel);

    // Simultaneous request
    expect(
      client.get(
        serverUrl.resolve('/delayed'),
        headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        },
      ),
      completion(
        predicate((result) => (result as http.Response).statusCode == 200),
      ),
    );
    // Cancelled request
    await expectLater(
      client.get(
        serverUrl.resolve('/delayed'),
        headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        },
        cancellationToken: token,
      ),
      throwsA(isA<CancelledException>()),
    );
    // Post-cancel request
    expect(
      client.get(
        serverUrl.resolve('/delayed'),
        headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        },
      ),
      completion(
        predicate((result) => (result as http.Response).statusCode == 200),
      ),
    );
  });

  test('detachSocket returns a socket from an IOStreamedResponse', () async {
    var ioClient = HttpClient();
    var client = http_io.IOClient(ioClient);
    var request = http.Request('GET', serverUrl);

    var response = await client.send(request);
    var socket = await response.detachSocket();

    expect(socket, isNotNull);
  });

  test('runWithClient', () {
    final client = http.runWithClient(http.Client.new, TestClient.new);
    expect(client, isA<TestClient>());
  });

  test('runWithClient Client() return', () {
    final client = http.runWithClient(http.Client.new, http.Client.new);
    expect(client, isA<http_io.IOClient>());
  });

  test('runWithClient nested', () {
    late final http.Client client;
    late final http.Client nestedClient;
    http.runWithClient(() {
      http.runWithClient(() => nestedClient = http.Client(), TestClient2.new);
      client = http.Client();
    }, TestClient.new);
    expect(client, isA<TestClient>());
    expect(nestedClient, isA<TestClient2>());
  });

  test('runWithClient recursion', () {
    // Verify that calling the http.Client() factory inside nested Zones does
    // not provoke an infinite recursion.
    http.runWithClient(() {
      http.runWithClient(http.Client.new, http.Client.new);
    }, http.Client.new);
  });
}
