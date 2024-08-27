# Cancellation Token HTTP

A fork of [dart-lang/http](https://github.com/dart-lang/http) with support for request cancellation using [cancellation_token](https://pub.dev/packages/cancellation_token).


## Packages

Although this fork contains all of the packages from the source repo, currently only the `http` package has been updated with full support for cancellation.

| Package | Description | Version |
|---|---|---|
| [cancellation_token_http](pkgs/http/) | A composable, multi-platform, Future-based API for HTTP requests. | [![pub package](https://img.shields.io/pub/v/cancellation_token_http.svg)](https://pub.dev/packages/cancellation_token_http) |
| [http_client_conformance_tests](pkgs/http_client_conformance_tests/) | A library that tests whether implementations of package:http's `Client` class behave as expected. | |
| [cronet_http](pkgs/cronet_http/) | An Android Flutter plugin that provides access to the [Cronet](https://developer.android.com/guide/topics/connectivity/cronet/reference/org/chromium/net/package-summary) HTTP client. | [![pub package](https://img.shields.io/pub/v/cronet_http.svg)](https://pub.dev/packages/cronet_http) |
| [cupertino_http](pkgs/cupertino_http/) | A macOS/iOS Flutter plugin that provides access to the [Foundation URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system). | [![pub package](https://img.shields.io/pub/v/cupertino_http.svg)](https://pub.dev/packages/cupertino_http) |
| [flutter_http_example](pkgs/flutter_http_example/) | An Flutter app that demonstrates how to configure and use `package:http`. | — |

## Contributing

If you'd like to contribute to any of these packages, see the
[Contributing Guide](CONTRIBUTING.md).
