/// Support for doing something awesome.
///
/// More dartdocs go here.
library persistent;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/persistent_generator.dart';

Builder persistentBuilder(BuilderOptions opitions) => LibraryBuilder(
      PersistentGenerator(),
      generatedExtension: '.p.dart',
    );
