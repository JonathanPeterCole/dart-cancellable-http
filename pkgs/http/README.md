# Dart Cancellation Token: HTTP

A fork of Dart's [HTTP package](https://pub.dev/packages/http) with request cancellation using [cancellation_token](https://pub.dev/packages/cancellation_token).

**Currently based on version 1.2.1 of the [HTTP package](https://pub.dev/packages/http/versions/1.2.1).**

## Features

* Retains all original functionality of the HTTP package.
* Cancel HTTP requests using CancellationTokens.
* Pair with the [cancellation_token](https://pub.dev/packages/cancellation_token) package to make a cancellable API request and parse the response JSON in a cancellable isolate using a single token.

## Using

This package keeps the same APIs as the base HTTP package, but with the addition of optional `cancellationToken` parameters. For more information on CancellationTokens, refer to [CancellationTokens](https://pub.dev/packages/cancellation_token#cancellation-tokens).

```dart
import 'package:cancellation_token_http/http.dart' as http;

var token = http.CancellationToken();
try {
  // A single CancellationToken can be used for multiple requests
  var readResponse = await http.read(
    Uri.parse('https://example.com/foobar.txt'),
    cancellationToken: token,
  );
  var postResponse = await http.post(
    Uri.parse('https://example.com/whatsit/create'),
    body: {'name': 'doodle', 'color': 'blue'},
    cancellationToken: token,
  );
  print('Read response: $readReponse');
  print('Post response status: ${postResponse.statusCode}');
  print('Post response body: ${postResponse.body}');
} on http.CancelledException {
  // If `token.cancel()` is called, the request will be cancelled and a
  // CancelledException will be thrown
  print('Request cancelled');
}
```

## Parsing JSON in an isolate

To parse JSON responses in a cancellable isolate, add the cancellation_token package to your project and use the same CancellationToken for both the API request and `cancellableCompute()`:

```dart
import 'package:cancellation_token/cancellation_token.dart';
import 'package:cancellation_token_http/http.dart' as http;

Future<void> makeRequest() async {
  var token = CancellationToken();
  try {
    var response = await http.get(
      Uri.parse('https://example.com/bigjson'),
      cancellationToken: token,
    );
    var parsedResponse = cancellableCompute(
      _readAndParseJson,
      response.body,
      token,
    );
    print('Request and parse complete');
  } on CancelledException {
    // If `token.cancel()` is called, the request and response parsing will be
    // cancelled and a CancelledException will be thrown
    print('Request and parse cancelled');
  }
}

static ChunkyApiResponse _readAndParseJson(String json) {
  final Map<String, dynamic> decodedJson = jsonDecode(json);
  return ChunkyApiResponse.fromJson(decodedJson);
}
```
