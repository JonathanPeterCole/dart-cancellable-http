A library that tests whether implementations of `package:cancellation_token_http`
[`Client`](https://pub.dev/documentation/cancellation_token_http/latest/http/Client-class.html)
behave as expected.

This package is intended to be used in the tests of packages that implement
`package:cancellation_token_http`
[`Client`](https://pub.dev/documentation/cancellation_token_http/latest/http/Client-class.html).

The tests work by starting a series of test servers and running the provided
`package:cancellation_token_http`
[`Client`](https://pub.dev/documentation/cancellation_token_http/latest/http/Client-class.html)
against them.

## Usage

`package:cancellation_token_http_client_conformance_tests` is meant to be used in the tests suite
of a `package:cancellation_token_http`
[`Client`](https://pub.dev/documentation/cancellation_token_http/latest/http/Client-class.html)
like:

```dart
import 'package:cancellation_token_http/http.dart';
import 'package:test/test.dart';

import 'package:cancellation_token_http_client_conformance_tests/http_client_conformance_tests.dart';

class MyHttpClient extends BaseClient {
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // Your implementation here.
  }
}

void main() {
  group('client conformance tests', () {
    testAll(MyHttpClient());
  });
}
```

**Note**: This package does not have its own tests, instead it is
exercised by the tests in `package:cancellation_token_http`.
