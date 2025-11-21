# Research: Testing with flutter_dotenv v6.0.0

## Objective
Determine the correct way to load environment variables from a `.env` file during unit tests using the `flutter_dotenv` package, version 6.0.0. The previously attempted `dotenv.testLoad()` method was not found.

## Findings
According to the official documentation on pub.dev, the `loadFromString` method should be used for loading environment variables in a testing environment. This method allows loading variables from a static string, which can be read directly from a `.env` file.

### Correct Usage in Tests

```dart
// Loading from a file synchronously.
dotenv.loadFromString(fileInput: File('test/.env').readAsStringSync());
```

This approach is suitable for unit tests as it ensures the test environment is configured with the necessary variables without relying on the asynchronous `load` method used in the main application.

## Source
- **Official Documentation**: [flutter_dotenv | Flutter package](https://pub.dev/packages/flutter_dotenv)