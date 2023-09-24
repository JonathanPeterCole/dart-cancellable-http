// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cancellation_token_http/http.dart';
import 'package:cancellation_token_http/retry.dart';
import 'package:cancellation_token_http/testing.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group("doesn't retry when", () {
    test('a request has a non-503 error code', () async {
      final client = RetryClient(
          MockClient(expectAsync1((_) async => Response('', 502), count: 1)));
      final response = await client.get(Uri.http('example.org', ''));
      expect(response.statusCode, equals(502));
    });

    test("a request doesn't match when()", () async {
      final client = RetryClient(
          MockClient(expectAsync1((_) async => Response('', 503), count: 1)),
          when: (_) => false);
      final response = await client.get(Uri.http('example.org', ''));
      expect(response.statusCode, equals(503));
    });

    test('retries is 0', () async {
      final client = RetryClient(
          MockClient(expectAsync1((_) async => Response('', 503), count: 1)),
          retries: 0);
      final response = await client.get(Uri.http('example.org', ''));
      expect(response.statusCode, equals(503));
    });

    test('a request is cancelled', () async {
      final token = CancellationToken()..cancel();
      final client = RetryClient(
        MockClient(
          expectAsync1((_) async => Response('', 503), count: 1),
        ),
        when: (_) => true,
      );

      expect(
        client.get(Uri.http('example.org', ''), cancellationToken: token),
        throwsA(isA<CancelledException>()),
      );
    });
  });

  test('retries on a 503 by default', () async {
    var count = 0;
    final client = RetryClient(
        MockClient(expectAsync1((request) async {
          count++;
          return count < 2 ? Response('', 503) : Response('', 200);
        }, count: 2)),
        delay: (_) => Duration.zero);

    final response = await client.get(Uri.http('example.org', ''));
    expect(response.statusCode, equals(200));
  });

  test('retries on any request where when() returns true', () async {
    var count = 0;
    final client = RetryClient(
        MockClient(expectAsync1((request) async {
          count++;
          return Response('', 503,
              headers: {'retry': count < 2 ? 'true' : 'false'});
        }, count: 2)),
        when: (response) => response.headers['retry'] == 'true',
        delay: (_) => Duration.zero);

    final response = await client.get(Uri.http('example.org', ''));
    expect(response.headers, containsPair('retry', 'false'));
    expect(response.statusCode, equals(503));
  });

  test('retries on any request where whenError() returns true', () async {
    var count = 0;
    final client = RetryClient(
        MockClient(expectAsync1((request) async {
          count++;
          if (count < 2) throw StateError('oh no');
          return Response('', 200);
        }, count: 2)),
        whenError: (error, _) =>
            error is StateError && error.message == 'oh no',
        delay: (_) => Duration.zero);

    final response = await client.get(Uri.http('example.org', ''));
    expect(response.statusCode, equals(200));
  });

  test("doesn't retry a request where whenError() returns false", () async {
    final client = RetryClient(
        MockClient(expectAsync1((request) async => throw StateError('oh no'))),
        whenError: (error, _) => error == 'oh yeah',
        delay: (_) => Duration.zero);

    expect(client.get(Uri.http('example.org', '')),
        throwsA(isStateError.having((e) => e.message, 'message', 'oh no')));
  });

  test('retries three times by default', () async {
    final client = RetryClient(
        MockClient(expectAsync1((_) async => Response('', 503), count: 4)),
        delay: (_) => Duration.zero);
    final response = await client.get(Uri.http('example.org', ''));
    expect(response.statusCode, equals(503));
  });

  test('retries the given number of times', () async {
    final client = RetryClient(
        MockClient(expectAsync1((_) async => Response('', 503), count: 13)),
        retries: 12,
        delay: (_) => Duration.zero);
    final response = await client.get(Uri.http('example.org', ''));
    expect(response.statusCode, equals(503));
  });

  test('waits 1.5x as long each time by default', () {
    FakeAsync().run((fake) {
      var count = 0;
      final client = RetryClient(MockClient(expectAsync1((_) async {
        count++;
        if (count == 1) {
          expect(fake.elapsed, equals(Duration.zero));
        } else if (count == 2) {
          expect(fake.elapsed, equals(const Duration(milliseconds: 500)));
        } else if (count == 3) {
          expect(fake.elapsed, equals(const Duration(milliseconds: 1250)));
        } else if (count == 4) {
          expect(fake.elapsed, equals(const Duration(milliseconds: 2375)));
        }

        return Response('', 503);
      }, count: 4)));

      expect(client.get(Uri.http('example.org', '')), completes);
      fake.elapse(const Duration(minutes: 10));
    });
  });

  test('waits according to the delay parameter', () {
    FakeAsync().run((fake) {
      var count = 0;
      final client = RetryClient(
          MockClient(expectAsync1((_) async {
            count++;
            if (count == 1) {
              expect(fake.elapsed, equals(Duration.zero));
            } else if (count == 2) {
              expect(fake.elapsed, equals(Duration.zero));
            } else if (count == 3) {
              expect(fake.elapsed, equals(const Duration(seconds: 1)));
            } else if (count == 4) {
              expect(fake.elapsed, equals(const Duration(seconds: 3)));
            }

            return Response('', 503);
          }, count: 4)),
          delay: (requestCount) => Duration(seconds: requestCount));

      expect(client.get(Uri.http('example.org', '')), completes);
      fake.elapse(const Duration(minutes: 10));
    });
  });

  test('waits according to the delay list', () {
    FakeAsync().run((fake) {
      var count = 0;
      final client = RetryClient.withDelays(
          MockClient(expectAsync1((_) async {
            count++;
            if (count == 1) {
              expect(fake.elapsed, equals(Duration.zero));
            } else if (count == 2) {
              expect(fake.elapsed, equals(const Duration(seconds: 1)));
            } else if (count == 3) {
              expect(fake.elapsed, equals(const Duration(seconds: 61)));
            } else if (count == 4) {
              expect(fake.elapsed, equals(const Duration(seconds: 73)));
            }

            return Response('', 503);
          }, count: 4)),
          const [
            Duration(seconds: 1),
            Duration(minutes: 1),
            Duration(seconds: 12)
          ]);

      expect(client.get(Uri.http('example.org', '')), completes);
      fake.elapse(const Duration(minutes: 10));
    });
  });

  test('calls onRetry for each retry', () async {
    var count = 0;
    final client = RetryClient(
        MockClient(expectAsync1((_) async => Response('', 503), count: 3)),
        retries: 2,
        delay: (_) => Duration.zero,
        onRetry: expectAsync3((request, response, retryCount) {
          expect(request.url, equals(Uri.http('example.org', '')));
          expect(response?.statusCode, equals(503));
          expect(retryCount, equals(count));
          count++;
        }, count: 2));
    final response = await client.get(Uri.http('example.org', ''));
    expect(response.statusCode, equals(503));
  });

  test('copies all request attributes for each attempt', () async {
    final client = RetryClient.withDelays(
        MockClient(expectAsync1((request) async {
          expect(request.contentLength, equals(5));
          expect(request.followRedirects, isFalse);
          expect(request.headers, containsPair('foo', 'bar'));
          expect(request.maxRedirects, equals(12));
          expect(request.method, equals('POST'));
          expect(request.persistentConnection, isFalse);
          expect(request.url, equals(Uri.http('example.org', '')));
          expect(request.body, equals('hello'));
          return Response('', 503);
        }, count: 2)),
        [Duration.zero]);

    final request = Request('POST', Uri.http('example.org', ''))
      ..body = 'hello'
      ..followRedirects = false
      ..headers['foo'] = 'bar'
      ..maxRedirects = 12
      ..persistentConnection = false;

    final response = await client.send(request);
    expect(response.statusCode, equals(503));
  });

  test('async when, whenError and onRetry', () async {
    final client = RetryClient(
      MockClient(expectAsync1(
          (request) async => request.headers['Authorization'] != null
              ? Response('', 200)
              : Response('', 401),
          count: 2)),
      retries: 1,
      delay: (_) => Duration.zero,
      when: (response) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return response.statusCode == 401;
      },
      whenError: (error, stackTrace) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return false;
      },
      onRetry: (request, response, retryCount) async {
        expect(response?.statusCode, equals(401));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        request.headers['Authorization'] = 'Bearer TOKEN';
      },
    );

    final response = await client.get(Uri.http('example.org', ''));
    expect(response.statusCode, equals(200));
  });

  group('handles cancellation', () {
    test('during the request', () {
      final token = CancellationToken();
      final client = RetryClient(
        MockClient(
          (_) async => Future.delayed(
            const Duration(hours: 1),
            () => Response('', 503),
          ),
        ),
      );

      expect(
        client.get(Uri.http('example.org', ''), cancellationToken: token),
        throwsA(isA<CancelledException>()),
      );

      token.cancel();
    });

    test('during the retry delay', () async {
      // Use a completer to wait until the delay begins before cancelling the
      // token.
      final onDelayCompleter = Completer<void>();

      final token = CancellationToken();
      final client = RetryClient(
        MockClient(expectAsync1((_) async => Response('', 503), max: 1)),
        delay: expectAsync1((requestCount) {
          onDelayCompleter.complete();
          return const Duration(hours: 1);
        }, max: 1),
      );

      expect(
        client.get(Uri.http('example.org', ''), cancellationToken: token),
        throwsA(isA<CancelledException>()),
      );

      await onDelayCompleter.future;

      token.cancel();
    });

    test('during when callback', () async {
      // Use a completer to wait until the when callback is called before
      // cancelling the token.
      final onWhenCompleter = Completer<void>();

      final token = CancellationToken();
      final client = RetryClient(
        MockClient((_) async => Response('', 503)),
        delay: (_) => Duration.zero,
        when: expectAsync1((response) async {
          onWhenCompleter.complete();
          return Future.delayed(const Duration(hours: 1), () => false);
        }),
      );

      expect(
        client.get(Uri.http('example.org', ''), cancellationToken: token),
        throwsA(isA<CancelledException>()),
      );

      await onWhenCompleter.future;

      token.cancel();
    });

    test('during whenError callback', () async {
      // Use a completer to wait until the whenError callback is called before
      // cancelling the token.
      final onWhenErrorCompleter = Completer<void>();

      final token = CancellationToken();
      final client = RetryClient(
        MockClient((_) async => throw Exception('Fake request error')),
        delay: (_) => Duration.zero,
        whenError: (_, __) async {
          onWhenErrorCompleter.complete();
          return Future.delayed(const Duration(hours: 1), () => false);
        },
      );

      expect(
        client.get(Uri.http('example.org', ''), cancellationToken: token),
        throwsA(isA<CancelledException>()),
      );

      await onWhenErrorCompleter.future;

      token.cancel();
    });

    test('during onRetry callback', () async {
      // Use a completer to wait until the whenError callback is called before
      // cancelling the token.
      final onOnRetryCompleter = Completer<void>();

      final token = CancellationToken();
      final client = RetryClient(
        MockClient((_) async => Response('', 503)),
        delay: (_) => Duration.zero,
        onRetry: (_, __, ___) async {
          onOnRetryCompleter.complete();
          return Future.delayed(const Duration(hours: 1), () => false);
        },
      );

      expect(
        client.get(Uri.http('example.org', ''), cancellationToken: token),
        throwsA(isA<CancelledException>()),
      );

      await onOnRetryCompleter.future;

      token.cancel();
    });
  });
}
