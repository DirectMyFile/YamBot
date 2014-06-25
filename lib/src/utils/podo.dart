part of yambot.utils;

class Serializable {
  String toJSON() {
    return JSON.encoder.convert(toMap());
  }

  Map toMap() {
    return PodoTransformer.toMap(this);
  }
}

/* Marker Mixin for PODO Objects */
class PODO {
  dynamic operator [](String name) {
    var instance = reflect(this);
    var names = instance.type.declarations.keys.map((a) => MirrorSystem.getName(a));
    if (!names.contains(name)) {
      return null;
    } else {
      return instance.getField(MirrorSystem.getSymbol(name));
    }
  }

  dynamic operator []=(String name, dynamic value) {
    var instance = reflect(this);
    var names = instance.type.declarations.keys.map((a) => MirrorSystem.getName(a));
    if (!names.contains(name)) {
      throw new Exception("no such property '${name}'");
    } else {
      return instance.setField(MirrorSystem.getSymbol(name), value);
    }
  }

  @override
  String toString() => "${PodoTransformer.toMap(this)}";
}

class PodoTransformer {
  static Map<String, Object> toMap(Object object) {
    var instance = reflect(object);

    var map = <String, Object>{
    };

    var members = instance.type.declarations.values.where((m) => m is VariableMirror && !m.isPrivate && !m.isStatic);

    for (VariableMirror member in members) {
      var name = MirrorSystem.getName(member.simpleName);
      var value = _get_value(instance.getField(member.simpleName).reflectee);
      map[name] = value;
    }

    return map;
  }

  static void fromMap(Map<String, dynamic> map, that) {
    var im = reflect(that);
    var members = im.type.declarations.values.where((m) => m is VariableMirror && !m.isPrivate && !m.isStatic);

    for (var m in members) {
      var name = MirrorSystem.getName(m.simpleName);

      if (m.type is ClassMirror && map.containsKey(name)) {
        im.setField(m.simpleName, _parse_value(m.type, map[name]));
      }
    }
  }


  static dynamic _get_value(dynamic value) {
    if (value is String || value is num || value is bool) {
      return value;
    } else if (value is DateTime) {
      return value.toString().replaceFirst(' ', 'T');
    } else if (value is List) {
      return new List.from(value.map((i) => _get_value(i)));
    } else if (value is Map) {
      return new Map.fromIterables(value.keys, value.values.map((i) => _get_value(i)));
    } else {
      return toMap(value);
    }

    return null;
  }

  static DateTime _parse_date(dynamic value) {
    if (value is String)return DateTime.parse(value);
    if (value is num)return new DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    return null;
  }

  static dynamic _parse_value(ClassMirror type, dynamic value) {
    if (type.reflectedType == String)return value is String ? value : null;
    if (type.reflectedType == int)return value is num ? value.toInt() : 0;
    if (type.reflectedType == double)return value is num ? value.toDouble() : 0;
    if (type.reflectedType == num)return value is num ? value : 0;
    if (type.reflectedType == bool)return value is bool ? value : false;
    if (type.reflectedType == DateTime)return _parse_date(value);

    return _parse_complex(type, value);
  }

  static dynamic _parse_complex(ClassMirror type, dynamic value) {
    var result = type.newInstance(const Symbol(""), []).reflectee;

    if (result is List && value is List) {
      var valueType = type.typeArguments[0];

      if (valueType is ClassMirror) {
        for (var i in value)
          result.add(_parse_value(valueType, i));
      }
    } else if (result is Map && value is Map && value is! YamlMap) {
      var keyType = type.typeArguments[0];
      var valueType = type.typeArguments[1];

      if (keyType is ClassMirror && valueType is ClassMirror) {
        if ((keyType as ClassMirror).reflectedType == String) {
          value.forEach((k, v) => result[k] = _parse_value(valueType, v));
        }
      }
    } else if (result is PODO && value is Map && value is! YamlMap) {
      PODO podo = result;
      Map map = value;
      map.forEach((k, v) => result[k] = v);
    } else if (result is PODO && value is YamlMap) {
      fromMap(value, result);
    }

    return result;
  }
}