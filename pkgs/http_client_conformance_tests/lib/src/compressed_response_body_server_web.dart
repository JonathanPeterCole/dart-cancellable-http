// Generated by generate_server_wrappers.dart. Do not edit.

import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

export 'server_queue_helpers.dart' show StreamQueueOfNullableObjectExtension;

/// Starts the redirect test HTTP server out-of-process.
Future<StreamChannel<Object?>> startServer() async => spawnHybridUri(Uri(
    scheme: 'package',
    path:
        'http_client_conformance_tests/src/compressed_response_body_server.dart'));
