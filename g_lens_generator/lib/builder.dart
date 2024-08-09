import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:g_lens/g_lens.dart';

String _generatedLensTemplate({
  required String wholeType,
  required String partType,
  required String fieldName,
}) {
  return '''static final Lens<${wholeType}, ${partType}> ${fieldName}Lens = Lens(
			getter: (whole) => whole.${fieldName},
			setter: (whole, partValue) => whole.copyWith(${fieldName}: partValue),
			);''';
}

Builder lensGenerator(BuilderOptions options) =>
    PartBuilder([LensGenerator()], '.lens.dart');

class LensGenerator extends GeneratorForAnnotation<LensAnotation> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    return _generateDataType(element, annotation, buildStep);
  }
}

class Pair<T, S> {
  Pair(this.first, this.second);

  final T first;
  final S second;

  @override
  String toString() {
    return 'Pair{first: $first, second: $second}';
  }
}

Future<String> _generateDataType(
    Element element, ConstantReader annotation, BuildStep buildStep) async {
  if (element is! ClassElement) {
    throw Exception(
        '`lens` annotation must only be used on classes, if you want to use on fields, use `@lensField` instead');
  }

  final className = element.name.replaceAll('\$', '');

  final classElement = element;
  final genericConstructor =
      classElement.constructors.firstWhere((element) => element.name.isEmpty);

  final positionalFields = genericConstructor.parameters
      .where((p) => p.isPositional)
      .map((p) => p.name)
      .toList();

  final fieldsWithIndex = await Future.wait(
    classElement.fields.where((f) => !f.isSynthetic && !f.isStatic).map(
      (f) async {
        final isContainsAnnotation = f.metadata.any(
            (element) => element.toString().contains('LensFieldAnotation'));
        //field name
        final declaration =
            await buildStep.resolver.astNodeFor(f) as VariableDeclaration?;
        //field type
        final declarationList = declaration?.parent as VariableDeclarationList?;
        final positionalIndex = positionalFields.indexOf(f.name);
        return Pair(
          positionalIndex == -1 ? 9999 : positionalIndex,
          Field(
            f.name,
            declarationList?.type?.toSource() ?? 'dynamic',
            isPositional: positionalIndex != -1,
            isContainsAnnotation: isContainsAnnotation,
          ),
        );
      },
    ),
  );
  // đảm bảo rằng các field không phải là positional sẽ được đặt sau các field positional
  // note: mergeSort sẽ giữ nguyên thứ tự của các phần tử có cùng giá trị
  mergeSort<Pair<int, Field>>(fieldsWithIndex,
      compare: (a, b) => a.first.compareTo(b.first));

  final fields = fieldsWithIndex.map((e) => e.second).toList();

  return _generateLenses(className, fields);
}

String _generateLenses(String className, List<Field> fields) {
  const suppressClassWithStatics = '// ignore_for_file: unused_field';
  final hasAnyContainsAnnotation =
      fields.any((element) => element.isContainsAnnotation);
  final lenses = (hasAnyContainsAnnotation
          ? fields.where((element) => element.isContainsAnnotation)
          : fields)
      .map((f) {
    final name = f.name;
    final type = f.type;
    return _generatedLensTemplate(
      wholeType: className,
      partType: type,
      fieldName: name,
    );
  });
  final copyWith =
      '$className copyWith({${fields.map((f) => '${f.optionalType} ${f.name}').join(', ')},\n}) =>\n'
      '$className(${fields.map((f) => '${f.asConstructorParameterLabel}${f.name} ?? this.${f.name}').join(', \n')},\n);';
  final copyWithExtension = '''
  extension ${className}CopyWith on $className {
    $copyWith
  }
  ''';
  final lensesClass =
      '$suppressClassWithStatics\nmixin _${className}Lens{\n ${lenses.join()}\n}\n\n $copyWithExtension ';

  return lensesClass;
}

class Field {
  const Field(this.name, this.type,
      {required this.isPositional, this.isContainsAnnotation = false});

  final String name;
  final String type;
  final bool isPositional;
  final bool isContainsAnnotation;

  String get optionalType => type[type.length - 1] == '?' ? type : '$type?';
}

extension AsConstructorParameter on Field {
  String get asConstructorParameterLabel => isPositional ? '' : '$name: ';
}
