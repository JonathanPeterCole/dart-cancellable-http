import 'dart:async';
import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';

import 'base_request.dart';
import 'base_response.dart';
import 'exception.dart';
import 'io_client.dart';
import 'io_streamed_response.dart';

/// Exception thrown when the underlying [HttpClient] throws a
/// [SocketException].
///
/// Implements [SocketException] to avoid breaking existing users of
/// [IOClient] that may catch that exception.
class _ClientSocketException extends ClientException
    implements SocketException {
  final SocketException cause;
  _ClientSocketException(SocketException e, Uri uri)
      : cause = e,
        super(e.message, uri);

  @override
  InternetAddress? get address => cause.address;

  @override
  OSError? get osError => cause.osError;

  @override
  int? get port => cause.port;

  @override
  String toString() => 'ClientException with $cause, uri=$uri';
}

class _IOStreamedResponseV2 extends IOStreamedResponse
    implements BaseResponseWithUrl {
  @override
  final Uri url;

  _IOStreamedResponseV2(super.stream, super.statusCode,
      {required this.url,
      super.contentLength,
      super.request,
      super.headers,
      super.isRedirect,
      super.persistentConnection,
      super.reasonPhrase,
      super.inner});
}

/// Handles sending reguests with cancellation for [IOClient].
class IOSender with Cancellable {
  IOSender(
    BaseRequest request,
    HttpClient? httpClient,
    CancellationToken? cancellationToken,
  ) : completer = Completer() {
    _send(request, httpClient, cancellationToken);
  }

  final Completer<IOStreamedResponse> completer;
  HttpClientRequest? ioRequest;
  HttpClientResponse? response;
  StreamController<List<int>>? responseStreamController;

  Future<IOStreamedResponse> get result => completer.future;

  /// Sends the request.
  ///
  /// [HttpClientResponse] currently doesn't support aborting with an exception
  /// like [HttpClientRequest] does, so [IOSender] instead creates it's own
  /// stream which response data is passed into. If the request is cancelled
  /// whilst receiving data, the cancellation exception is added to the stream
  /// before closing it, and the socket is detached and destroyed.
  Future<void> _send(
    BaseRequest request,
    HttpClient? httpClient,
    CancellationToken? cancellationToken,
  ) async {
    if (!maybeAttach(cancellationToken)) return;

    if (httpClient == null) {
      return completer.completeError(
        ClientException(
          'HTTP request failed. Client is already closed.',
          request.url,
        ),
        StackTrace.current,
      );
    }

    try {
      // Finalise the request and open the connection
      final requestStream = request.finalize();
      ioRequest = (await httpClient.openUrl(request.method, request.url))
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..contentLength = (request.contentLength ?? -1)
        ..persistentConnection = request.persistentConnection;

      // Cancel the request immediately if the token was cancelled
      if (cancellationToken?.isCancelled ?? false) {
        await ioRequest!.close();
        return;
      }

      // Add the request headers
      request.headers.forEach((name, value) {
        ioRequest!.headers.set(name, value);
      });

      // Send the request body
      response = await requestStream.pipe(ioRequest!) as HttpClientResponse;
      ioRequest = null;

      // Get the headers from the response
      final headers = <String, String>{};
      response!.headers.forEach((key, values) {
        // TODO: Remove trimRight() when
        // https://github.com/dart-lang/sdk/issues/53005 is resolved and the
        // package:http SDK constraint requires that version or later.
        headers[key] = values.map((value) => value.trimRight()).join(',');
      });

      // Prepare a wrapper response stream to convert HttpExceptions to
      // ClientExceptions and handle onDone
      responseStreamController = StreamController();
      response!.listen(
        (data) => responseStreamController?.add(data),
        onError: (Object error, StackTrace? stackTrace) {
          if (error is HttpException) {
            error = ClientException(error.message, error.uri);
          }
          responseStreamController?.addError(error, stackTrace);
        },
        onDone: () {
          detach();
          responseStreamController?.close();
          responseStreamController = null;
        },
      );

      // Return the response with the wrapped stream
      completer.complete(
        _IOStreamedResponseV2(
          responseStreamController!.stream,
          response!.statusCode,
          contentLength:
              response!.contentLength == -1 ? null : response!.contentLength,
          request: request,
          headers: headers,
          isRedirect: response!.isRedirect,
          url: response!.redirects.isNotEmpty
              ? response!.redirects.last.location
              : request.url,
          persistentConnection: response!.persistentConnection,
          reasonPhrase: response!.reasonPhrase,
          inner: response,
        ),
      );
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(_convertException(error, request), stackTrace);
      }
      detach();
    }
  }

  @override
  void onCancel(Exception cancelException) {
    super.onCancel(cancelException);
    if (!completer.isCompleted) {
      completer.completeError(cancelException, cancellationStackTrace);
    }
    // Add the cancellation exception and close the response stream if it's
    // active
    responseStreamController
      ?..addError(cancelException, cancellationStackTrace)
      ..close();
    responseStreamController = null;
    // Abort the HTTP request if cancelled whilst sending the request
    ioRequest?.abort(cancelException, cancellationStackTrace);
    // Detatch and destroy the socket to close the connection if cancelled
    // whilst receiving the response body
    response?.detachSocket().then((value) => value.destroy());
  }

  Object _convertException(Object error, BaseRequest request) {
    if (error is SocketException) {
      return _ClientSocketException(error, request.url);
    } else if (error is HttpException) {
      return ClientException(error.message, error.uri);
    } else {
      return error;
    }
  }
}
