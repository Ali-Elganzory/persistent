<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

## Welcome to [Persistent]().

#### A code generator for locally persistent classes.

-----------

## Installation

Add `persistent` as a dev dependency in your [pubspec.yaml](https://flutter.dev/docs/development/packages-and-plugins/using-packages) file.
This contains the generator itself.

```yaml
dev_dependencies:
    persistent:
```

Add `persistent_annotations` as a dependency in your [pubspec.yaml](https://flutter.dev/docs/development/packages-and-plugins/using-packages) file.
This contains the annotations that act as markers for the generator.

```yaml
dependencies:
    persistent_annotations:
```

## Getting started

Import the annotations and the local storage service to be used.

SharedPreferences for example.

```dart
import 'package:persistent_annotations:persistent_annotations.dart';
import 'package:shared_preferences:shared_preferences.dart';
```

Now, you're set to go.

## Usage

Let's explain with an example. 

A local user session is to be persisted. The data to persist locally, are an access token and its expiration date.


Let's get to it. We'll call the model `LocalSessionApi`.

1. First declare an abstract class for the generator.
Its name can be `LocalSessionApi` with the suffix `Base`, which is `LocalSessionApiBase`.

```dart
abstract class LocalSessionApiBase {
    
}
```

2. Add the data to be persisted as late fields.

```dart
abstract class LocalSessionApiBase {
   late String accessToken;

   late DateTime expirationDate;
}
```

3. Annotate the class and its fields.

```dart
@persistent
abstract class LocalSessionApiBase {
   @Default('')
   late String accessToken;

   @Default('2022-9-10 15:04:07')
   late DateTime expirationDate;
}
```

4. Finally, generate.

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

You can also watch for any changes in code and rebuild accordingly.
This can be faster during development of the classes.

```bash
flutter packages pub run build_runner watch --delete-conflicting-outputs
```

## Contributing

Everyone is more than welcomed to contribute to the code.

For any suggestions you can open an issue on github or DM me @ alielganzory@hotmail.com.
