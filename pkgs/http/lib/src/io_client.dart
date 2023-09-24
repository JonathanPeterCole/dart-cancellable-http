// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';

import 'base_client.dart';
import 'base_request.dart';
import 'client.dart';
import 'exception.dart';
import 'io_sender.dart';
import 'io_streamed_response.dart';

/// Create an [IOClient].
///
/// Used from conditional imports, matches the definition in `client_stub.dart`.
BaseClient createClient() {
  if (const bool.fromEnvironment('no_default_http_client')) {
    throw StateError('no_default_http_client was defined but runWithClient '
        'was not used to configure a Client implementation.');
  }
  return IOClient();
}

/// A `dart:io`-based HTTP [Client].
///
/// If there is a socket-level failure when communicating with the server
/// (for example, if the server could not be reached), [IOClient] will emit a
/// [ClientException] that also implements [SocketException]. This allows
/// callers to get more detailed exception information for socket-level
/// failures, if desired.
///
/// For example:
/// ```dart
/// final client = http.Client();
/// late String data;
/// try {
///   data = await client.read(Uri.https('example.com', ''));
/// } on SocketException catch (e) {
///   // Exception is transport-related, check `e.osError` for more details.
/// } on http.ClientException catch (e) {
///   // Exception is HTTP-related (e.g. the server returned a 404 status code).
///   // If the handler for `SocketException` were removed then all exceptions
///   // would be caught by this handler.
/// }
/// ```
class IOClient extends BaseClient {
  /// The underlying `dart:io` HTTP client.
  HttpClient? _inner;

  IOClient([HttpClient? inner]) : _inner = inner ?? HttpClient();

  /// Sends an HTTP request and asynchronously returns the response.
  @override
  Future<IOStreamedResponse> send(
    BaseRequest request, {
    CancellationToken? cancellationToken,
  }) =>
      IOSender(request, _inner, cancellationToken).result;

  /// Closes the client.
  ///
  /// Terminates all active connections. If a client remains unclosed, the Dart
  /// process may not terminate.
  @override
  void close() {
    if (_inner != null) {
      _inner!.close(force: true);
      _inner = null;
    }
  }
}
