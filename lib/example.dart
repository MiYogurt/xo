import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';



class CopyBuilder implements Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async{
    var inputId = buildStep.inputId;
    var contents = await buildStep.readAsString(inputId);
    var copy = inputId.changeExtension('.g.txt');await buildStep.writeAsString(copy, '// Copied from $inputId\n$contents');
  }

  @override
  Map<String, List<String>> get buildExtensions => {'.txt' : ['.g.txt']};
}


class ResolvingBuilder implements Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var entryLib = await buildStep.inputLibrary;
    var resolver = buildStep.resolver;
    var visibleLibraries = await resolver.libraries.length;

    var info = buildStep.inputId.addExtension('.info');
    print('debug start');
    entryLib.importedLibraries.forEach(print);
    entryLib.imports.forEach(print);
    allElements(entryLib).forEach(print);
    print('debug end');
    await buildStep.writeAsString(info, '''
         Input ID: ${buildStep.inputId}
     Member count: ${allElements(entryLib).length}
Visible libraries: $visibleLibraries
''');
  }

  @override
  Map<String, List<String>> get buildExtensions => const{
    '.dart' : ['.dart.info']
  };
}

Iterable<Element> allElements(LibraryElement element) sync* {
  for (var cu in element.units) {
    yield* cu.functionTypeAliases;
    yield* cu.functions;
    yield* cu.mixins;
    yield* cu.topLevelVariables;
    yield* cu.types;
  }
}