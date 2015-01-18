library polymorphic.test.common;

import "package:unittest/unittest.dart";

import "package:quiver/async.dart";
import "dart:async";
import "dart:mirrors";

export "package:unittest/unittest.dart";
export "package:unittest/compact_vm_config.dart" show useCompactVMConfiguration;
export "package:unittest/vm_config.dart" show useVMConfiguration;

class Test {
  final String name;
  final List<dynamic> inputs;

  const Test(this.name, {this.inputs});
}

class Start {
  const Start();
}

class Group {
  final String name;
  final List<Type> subgroups;

  const Group(this.name, {this.subgroups});
}

class SubGroup {
  final String name;
  final List<Type> subgroups;

  const SubGroup(this.name, {this.subgroups});
}

class ExternalGroup {
  final String name;

  const ExternalGroup(this.name);
}

class Setup {
  const Setup();
}

class Destroy {
  const Destroy();
}

class Configure {
  const Configure();
}

class Mocker {
  final Type type;

  const Mocker(this.type);
}

void main() {
  findFunctionAnnotations(Configure).forEach((s) {
    s.function();
  });

  scanLibrary(currentMirrorSystem().isolate.rootLibrary);
}

void scanLibrary(LibraryMirror lib) {
  void setupTest(FunctionAnnotation a) {
    test(a.metadata.name, () {
      if (a.metadata.inputs != null) {
        var group = new FutureGroup();
        for (var input in a.metadata.inputs) {
          var r = new Future.value(a.function(input));
          group.add(r);
        }
        return group.future;
      } else {
        return a.function();
      }
    });
  }

  void scanGroup(ClassAnnotation g) {
    group(g.metadata.name, () {
      var i = g.mirror.newInstance(const Symbol(""), []);
      var tests = findFunctionAnnotations(Test, instance: i, lib: lib);
      var setups = findFunctionAnnotations(Setup, instance: i, lib: lib);
      var destroys = findFunctionAnnotations(Destroy, instance: i, lib: lib);

      for (var s in setups) {
        setUp(() {
          return s.function();
        });
      }

      for (var s in destroys) {
        tearDown(() {
          return s.function();
        });
      }

      for (var f in tests) {
        setupTest(f);
      }

      if (g.metadata.subgroups != null) {
        for (Type sub in g.metadata.subgroups) {
          var clazz = reflectClass(sub);
          var s = clazz.metadata.firstWhere(
              (it) => it.reflectee is SubGroup).reflectee;
          var a = new ClassAnnotation()
            ..metadata = s
            ..mirror = clazz;
          scanGroup(a);
        }
      }
    });
  }

  findClassesAnnotation(Group, lib: lib).forEach((g) {
    scanGroup(g);
  });

  findFunctionAnnotations(Test, lib: lib).forEach((t) {
    setupTest(t);
  });

  findFunctionAnnotations(Start, lib: lib).forEach((s) {
    s.function();
  });

  findFunctionAnnotations(Mocker, lib: lib).forEach((m) {
    var type = m.metadata.type;
    _mocks[type] = m.function;
  });

  var externals = lib.libraryDependencies.where((it) =>
      it.isImport && it.metadata.any((it) => it.reflectee is ExternalGroup));

  for (var external in externals) {
    ExternalGroup g = external.metadata.firstWhere(
        (it) => it.reflectee is ExternalGroup).reflectee;

    group(g.name, () {
      scanLibrary(external.targetLibrary);
    });
  }
}

class FunctionAnnotation<T> {
  T metadata;
  Function function;
}

class ClassAnnotation<T> {
  T metadata;
  ClassMirror mirror;
}

List<ClassAnnotation> findClassesAnnotation(Type type, {LibraryMirror lib}) =>
    (lib == null ? currentMirrorSystem().isolate.rootLibrary :
        lib).declarations.values
    .where((it) => it is ClassMirror &&
        it.metadata.any((a) => reflectType(type).isAssignableTo(a.type)))
    .map((it) {
  return new ClassAnnotation()
    ..metadata = (it.metadata.firstWhere(
        (it) => reflectType(type).isAssignableTo(it.type)).reflectee)
    ..mirror = it;
});

Map<Type, Function> _mocks = {};

dynamic mockOf(Type type) {
  if (_mocks.containsKey(type)) {
    return _mocks[type]();
  } else {
    throw new ArgumentError("No Mock for given type.");
  }
}

List<FunctionAnnotation> findFunctionAnnotations(Type type,
    {InstanceMirror instance, LibraryMirror lib}) {
  var l = (lib == null ? currentMirrorSystem().isolate.rootLibrary : lib);
  var result = [];
  var t = reflectType(type);
  var decl = instance != null ? instance.type.declarations.values :
      l.declarations.values;

  var mm = decl.where((it) =>
      it is MethodMirror && it.metadata.any((f) => t.isAssignableTo(f.type)));

  for (var m in mm) {
    var a = new FunctionAnnotation();
    a.metadata =
        m.metadata.firstWhere((it) => t.isAssignableTo(it.type)).reflectee;
    a.function = ([input]) {
      var args = [];
      if (input != null) args.add(input);
      if (instance != null) {
        return instance.invoke(m.simpleName, args).reflectee;
      } else {
        return l.invoke(m.simpleName, args).reflectee;
      }
    };
    result.add(a);
  }
  return result;
}
