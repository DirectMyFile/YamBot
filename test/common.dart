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

class Setup {
  const Setup();
}

class Destroy {
  const Destroy();
}

class Configure {
  const Configure();
}

void main() {
  findFunctionAnnotations(Configure).forEach((s) {
    s.function();
  });

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
      var tests = findFunctionAnnotations(Test, instance: i);
      var setups = findFunctionAnnotations(Setup, instance: i);
      var destroys = findFunctionAnnotations(Destroy, instance: i);

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
          var s = clazz.metadata.firstWhere((it) => it.reflectee is SubGroup).reflectee;
          var a = new ClassAnnotation()..metadata = s..mirror = clazz;
          scanGroup(a);
        }
      }
    });
  }

  findClassesAnnotation(Group).forEach((g) {
    scanGroup(g);
  });

  findFunctionAnnotations(Test).forEach((t) {
    setupTest(t);
  });

  findFunctionAnnotations(Start).forEach((s) {
    s.function();
  });
}

class FunctionAnnotation<T> {
  T metadata;
  Function function;
}

class ClassAnnotation<T> {
  T metadata;
  ClassMirror mirror;
}

List<ClassAnnotation> findClassesAnnotation(Type type) => currentMirrorSystem().isolate.rootLibrary.declarations.values.where((it) => it is ClassMirror && it.metadata.any((a) => reflectType(type).isAssignableTo(a.type))).map((it) {
  return new ClassAnnotation()
      ..metadata = (it.metadata.firstWhere((it) => reflectType(type).isAssignableTo(it.type)).reflectee)
      ..mirror = it;
});

List<FunctionAnnotation> findFunctionAnnotations(Type type, {InstanceMirror instance}) {
  var result = [];
  var t = reflectType(type);
  var decl = instance == null ? currentMirrorSystem().isolate.rootLibrary.declarations.values : instance.type.declarations.values;

  var mm = decl.where((it) => it is MethodMirror && it.metadata.any((f) => t.isAssignableTo(f.type)));

  for (var m in mm) {
    var a = new FunctionAnnotation();
    a.metadata = m.metadata.firstWhere((it) => t.isAssignableTo(it.type)).reflectee;
    a.function = ([input]) {
      var args = [];
      if (input != null) args.add(input);
      if (instance != null) {
        return instance.invoke(m.simpleName, args).reflectee;
      } else {
        return currentMirrorSystem().isolate.rootLibrary.invoke(m.simpleName, args).reflectee;
      }
    };
    result.add(a);
  }
  return result;
}
