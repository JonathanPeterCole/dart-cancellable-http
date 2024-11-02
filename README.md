# Cancellation Token HTTP

A fork of [dart-lang/http](https://github.com/dart-lang/http) with support for request cancellation using [cancellation_token](https://pub.dev/packages/cancellation_token).


## Packages

Although this fork contains all of the packages from the source repo, only the following packages have been updated with cancellation:

| Package | Description | Version |
|---|---|---|
| [cancellation_token_http](pkgs/http/) | A composable, multi-platform, Future-based API for HTTP requests. | [![pub package](https://img.shields.io/pub/v/cancellation_token_http.svg)](https://pub.dev/packages/cancellation_token_http) |
| [cancellation_token_http_client_conformance_tests](pkgs/http_client_conformance_tests/) | A library that tests whether implementations of package:cancellation_token_http's `Client` class behave as expected. | |

## Testing

If you get the following error when running tests, make sure you use `dart test` instead of `flutter test`:
```
IsolateSpawnException: Unable to spawn isolate: Error: Couldn't resolve the package 'cancellation_token_http' in 'package:cancellation_token_http/http.dart'.
```
