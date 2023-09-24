import 'dart:async';
import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';

import 'base_request.dart';
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
  HttpClientRequest? clientRequest;
  HttpClientResponse? clientResponse;
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
      clientRequest = (await httpClient.openUrl(request.method, request.url))
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..contentLength = (request.contentLength ?? -1)
        ..persistentConnection = request.persistentConnection;

      // Cancel the request immediately if the token was cancelled
      if (cancellationToken?.isCancelled ?? false) {
        await clientRequest!.close();
        return;
      }

      // Add the request headers
      request.headers.forEach((name, value) {
        clientRequest!.headers.set(name, value);
      });

      // Send the request body
      clientResponse =
          await requestStream.pipe(clientRequest!) as HttpClientResponse;
      clientRequest = null;

      // Get the headers from the response
      final responseHeaders = <String, String>{};
      clientResponse!.headers.forEach((key, values) {
        responseHeaders[key] = values.join(',');
      });

      // Prepare the response stream and pass the client response data into it
      responseStreamController = StreamController();
      clientResponse!.listen(
        (data) => responseStreamController?.add(data),
        onError: (Object error, StackTrace? stackTrace) {
          responseStreamController?.addError(
            _convertException(error, request),
            stackTrace,
          );
        },
        onDone: () {
          detach();
          responseStreamController?.close();
          responseStreamController = null;
        },
      );

      // Return the response with the response stream
      completer.complete(
        IOStreamedResponse(
          responseStreamController!.stream,
          clientResponse!.statusCode,
          contentLength: clientResponse!.contentLength == -1
              ? null
              : clientResponse!.contentLength,
          request: request,
          headers: responseHeaders,
          isRedirect: clientResponse!.isRedirect,
          persistentConnection: clientResponse!.persistentConnection,
          reasonPhrase: clientResponse!.reasonPhrase,
          inner: clientResponse,
        ),
      );
    } catch (e, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(_convertException(e, request), stackTrace);
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
    clientRequest?.abort(cancelException, cancellationStackTrace);
    // Detatch and destroy the socket to close the connection if cancelled
    // whilst receiving the response body
    clientResponse?.detachSocket().then((value) => value.destroy());
  }

  Object _convertException(Object e, BaseRequest request) {
    if (e is SocketException) {
      return _ClientSocketException(e, request.url);
    } else if (e is HttpException) {
      return ClientException(e.message, e.uri);
    } else {
      return e;
    }
  }
}
