// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:async';

import 'package:cancellation_token/cancellation_token.dart';
import 'package:cancellation_token_http/browser_client.dart';
import 'package:cancellation_token_http/http.dart' as http;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('#send a StreamedRequest', () async {
    var client = BrowserClient();
    var request = http.StreamedRequest('POST', echoUrl);

    var responseFuture = client.send(request);
    request.sink.add('{"hello": "world"}'.codeUnits);
    unawaited(request.sink.close());

    var response = await responseFuture;
    var bytesString = await response.stream.bytesToString();
    client.close();

    expect(bytesString, equals('{"hello": "world"}'));
  }, skip: 'Need to fix server tests for browser');

  test('#send with an invalid URL', () {
    var client = BrowserClient();
    var url = Uri.http('http.invalid', '');
    var request = http.StreamedRequest('POST', url);

    expect(
        client.send(request), throwsClientException('XMLHttpRequest error.'));

    request.sink.add('{"hello": "world"}'.codeUnits);
    request.sink.close();
  });

  test('send with cancellation during request', () {
    var client = BrowserClient();
    var request = http.StreamedRequest('GET', echoUrl);
    var token = CancellationToken();

    expect(
      client.send(request, cancellationToken: token),
      throwsA(isA<CancelledException>()),
    );
    token.cancel();
  });

  test('send with cancellation before request', () {
    var client = BrowserClient();
    var request = http.StreamedRequest('GET', echoUrl);
    var token = CancellationToken()..cancel();

    expect(
      client.send(request, cancellationToken: token),
      throwsA(isA<CancelledException>()),
    );
  });
}
