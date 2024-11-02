import 'dart:async';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

/// Starts an HTTP server that notifiers the test when a request has been
/// received and waits for a message from the test before closing the response.
///
/// Channel protocol:
///    On Startup:
///     - send port
///    On Request Received:
///     - send the received request path (e.g. '/get') as a String
///    When 'close' message received with the request path:
///     - close the response
///    When 'close' message received without a request path:
///     - exit
void hybridMain(StreamChannel<Object?> channel) async {
  final Stream<Object?> channelBroadcastStream =
      channel.stream.asBroadcastStream();
  late HttpServer server;

  server = (await HttpServer.bind('localhost', 0))
    ..listen((request) async {
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      if (request.method == 'OPTIONS') {
        // Handle a CORS preflight request:
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests
        request.response.headers
          ..set('Access-Control-Allow-Methods', '*')
          ..set('Access-Control-Allow-Headers', '*');
      } else {
        // Send the request path that was received.
        channel.sink.add(request.uri.path);
      }
      // Close the response when a 'close' message is received with the request
      // path.
      await channelBroadcastStream
          .where((message) => message == 'close:${request.uri.path}')
          .first;
      unawaited(request.response.close());
    });

  channel.sink.add(server.port);

  // Close the server if a 'close' message is received without a path.
  await channelBroadcastStream.where((message) => message == 'close').first;
  unawaited(server.close());
}
