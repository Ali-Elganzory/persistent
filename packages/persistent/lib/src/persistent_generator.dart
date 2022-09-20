import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';

import 'package:persistent_annotation/persistent_annotation.dart';

class PersistentGenerator extends GeneratorForAnnotation<Persistent> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final visitor = PersitentVisitor();

    element.visitChildren(visitor);

    final mixinName = '_\$${visitor.className}';
    final baseName = '${visitor.className}${visitor.suffix}';

    /************************/
    // Persisted model.
    /************************/
    final classModel = Mixin(
      (b) => b
        ..name = mixinName
        ..on = Reference(baseName)
        // Private fields.
        ..fields.addAll(
          [
            Field(
              (b) => b
                ..late = true
                ..type = Reference('PersistentStore')
                ..name = '_store',
            ),
            ...visitor.fields.map(
              (field) => Field(
                (b) => b
                  ..name = '_${field.name}'
                  ..type = Reference(
                    field.type.toString(),
                  )
                  ..assignment = Code('''
${field.type.toString() == 'DateTime' ? 'DateTime.parse(${field.defaultValue})' : '${field.defaultValue}'}
'''),
              ),
            ),
          ],
        )
        // Initializer.
        ..methods.addAll(
          [
            Method(
              (b) => b
                ..returns = Reference('Future<void>')
                ..name = 'init'
                ..modifier = MethodModifier.async
                ..body = Code('''
_store = PersistentStore();
return _store.init();
'''),
            ),
          ],
        )
        // Getters.
        ..methods.addAll(
          visitor.fields.map(
            (field) => Method(
              (b) => b
                ..annotations.add(CodeExpression(Code('override')))
                ..returns = Reference('${field.type}')
                ..type = MethodType.getter
                ..name = field.name
                ..body = Code('return _${field.name};'),
            ),
          ),
        )
        // Setters.
        ..methods.addAll(
          visitor.fields.map(
            (field) => Method(
              (b) => b
                ..annotations.add(CodeExpression(Code('override')))
                ..type = MethodType.setter
                ..name = field.name
                ..requiredParameters.addAll(
                  [
                    Parameter(
                      (b) => b
                        ..type = Reference('${field.type}')
                        ..name = 'v',
                    ),
                  ],
                )
                ..body = Code('''
_store.put('${visitor.className}::${field.name}', ${field.type.toString() == 'DateTime' ? 'v.toIso8601String()' : 'v'})
.then((res) {
  if (res) { _${field.name} = v; }
});
'''),
            ),
          ),
        )
        // Asynchronous Getters.
        ..methods.addAll(
          visitor.fields.map(
            (field) => Method(
              (b) => b
                ..returns = Reference('Future<${field.type}>')
                ..name =
                    'get${field.name[0].toUpperCase() + field.name.substring(1)}'
                ..modifier = MethodModifier.async
                ..body = Code('''
var v = await _store.get('${visitor.className}::${field.name}');
if (v != null) { 
  ${field.type.toString() == 'DateTime' ? 'v = DateTime.parse(v);' : ''}
  _${field.name} = v; 
}
return _${field.name};
'''),
            ),
          ),
        )
        // Asynchronous Setters.
        ..methods.addAll(
          visitor.fields.map(
            (field) => Method(
              (b) => b
                ..returns = Reference('Future<void>')
                ..name =
                    'set${field.name[0].toUpperCase() + field.name.substring(1)}'
                ..modifier = MethodModifier.async
                ..requiredParameters.addAll(
                  [
                    Parameter(
                      (b) => b
                        ..type = Reference('${field.type}')
                        ..name = 'v',
                    ),
                  ],
                )
                ..body = Code('''
final res= await _store.put('${visitor.className}::${field.name}', ${field.type.toString() == 'DateTime' ? 'v.toIso8601String()' : 'v'});
if (res) { _${field.name} = v; }
'''),
            ),
          ),
        ),
    );

    /************************/
    // Store model.
    /************************/
    final storeModel = Class(
      (b) => b
        ..name = 'PersistentStore'
        ..fields.addAll(
          [
            Field(
              (b) => b
                ..name = '_storeImpl'
                ..type = Reference(
                  'SharedPreferences?',
                ),
            ),
          ],
        )
        ..methods.addAll(
          [
            // Init.
            Method(
              (b) => b
                ..returns = Reference('Future<void>')
                ..name = 'init'
                ..modifier = MethodModifier.async
                ..body = Code(
                  '''
_storeImpl = await SharedPreferences.getInstance();
''',
                ),
            ),
            // Get.
            Method(
              (b) => b
                ..returns = Reference('Future<T?>')
                ..name = 'get<T>'
                ..requiredParameters.addAll(
                  [
                    Parameter(
                      (b) => b
                        ..type = Reference('String')
                        ..name = 'key',
                    ),
                  ],
                )
                ..modifier = MethodModifier.async
                ..body = Code(
                  '''
try {
  final v = _storeImpl?.getString(key);
  if (v == null){
    return null;
  } else {
    return jsonDecode(v) as T;
  }
} catch (e){
  return null;
}
''',
                ),
            ),
            // Put.
            Method(
              (b) => b
                ..returns = Reference('Future<bool>')
                ..name = 'put'
                ..requiredParameters.addAll(
                  [
                    Parameter(
                      (b) => b
                        ..type = Reference('String')
                        ..name = 'key',
                    ),
                    Parameter(
                      (b) => b
                        ..type = Reference('dynamic')
                        ..name = 'value',
                    ),
                  ],
                )
                ..modifier = MethodModifier.async
                ..body = Code(
                  '''
try {
  return (await (_storeImpl?.setString(key, jsonEncode(value)))) ?? false;
} catch (e){
  return false;
}
''',
                ),
            ),
          ],
        ),
    );

    final emitter = DartEmitter();
    final exp = RegExp(r'[A-Z]+([a-z]+)');
    final partOfName = exp
        .allMatches(visitor.className)
        .map((m) => m.group(0))
        .join('_')
        .toLowerCase();

    return '''
part of '$partOfName.dart';

class ${visitor.className} = ${visitor.className}${visitor.suffix} with $mixinName;

${DartFormatter().format('${classModel.accept(emitter)}')}

${DartFormatter().format('${storeModel.accept(emitter)}')}
''';
  }
}

class PersitentVisitor extends SimpleElementVisitor {
  String className = '';
  final List<FieldInfo> fields = [];

  /// The suffix expected at the end
  /// of the annotated abstract class name.
  final String suffix = 'Base';

  @override
  visitConstructorElement(ConstructorElement element) {
    final typeName = element.returnType.toString();
    className = typeName.substring(0, typeName.length - suffix.length);
  }

  @override
  visitFieldElement(FieldElement element) {
    final defaultAnnotation = element.metadata.first;
    final defaultValue = defaultAnnotation
        .computeConstantValue()!
        .getField('value')!
        .toString()
        .split('(')[1];

    fields.add(
      FieldInfo(
        name: element.name,
        type: element.type,
        defaultValue: defaultValue.substring(0, defaultValue.length - 1),
      ),
    );
  }
}

class FieldInfo {
  final String name;
  final DartType type;
  final dynamic defaultValue;

  const FieldInfo({
    required this.name,
    required this.type,
    required this.defaultValue,
  });
}
