part of polymorphic.api;

typedef void StorageChecker(Map<String, dynamic> content);

class JsonStorageType extends StorageType {
  const JsonStorageType();
  
  @override
  Map<String, dynamic> decode(String input) =>
      JSON.decode(input);

  @override
  String encode(Map<String, dynamic> input) =>
      new JsonEncoder.withIndent("  ").convert(input);
}

abstract class StorageType {
  static const StorageType JSON = const JsonStorageType();
  
  const StorageType();
  
  String encode(Map<String, dynamic> input);
  Map<String, dynamic> decode(String input);
}

class Storage extends StorageContainer {
  final String path;
  
  StorageType type = StorageType.JSON;
  List<StorageChecker> _checkers = [];
  Map<String, dynamic> _entries;
  Timer _timer;
  
  Storage(this.path);
  
  bool _changed = false;

  void load() {
    var file = new File(path);
    
    if (!file.existsSync()) {
      _entries = {};
    } else {
      var content = file.readAsStringSync();
      var map = type.decode(content);
      
      if (map is! Map) {
        throw new Exception("JSON was not a map!");
      }

      for (var checker in _checkers) {
        checker(map);
      }

      _entries = map;
    }
  }

  void save() {
    var file = new File(path);
    
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    file.writeAsStringSync(type.encode(_entries) + "\n");
  }
  
  void startSaveTimer({Duration interval: const Duration(seconds: 2)}) {
    if (_timer != null) {
      throw new StateError("Timer already started.");
    }
    
    _timer = new Timer.periodic(interval, (timer) {
      if (_changed) {
        save();
      }
    });
  }
  
  void stopSaveTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }
  
  void destroy() {
    stopSaveTimer();
    save();
  }

  void addChecker(StorageChecker checker) {
    _checkers.add(checker);
  }
  
  Map<String, dynamic> asMap() => new Map.from(_entries);
  bool get isSaveTimerOn => _timer != null;

  @override
  Map<String, dynamic> get entries => _entries;

  @override
  void onChange() {
    _changed = true;
  }
  
  void delete() {
    destroy();
    var file = new File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
  
  bool get hasChangePending => _changed;
}

class SubStorage extends StorageContainer {
  final StorageContainer parent;
  final String key;
  
  SubStorage(this.parent, this.key) {
    if (!parent.entries.containsKey(key)) {
      parent.entries[key] = {};
      parent.onChange();
    }
  }
  
  @override
  Map<String, dynamic> get entries => parent.entries[key];

  @override
  void onChange() {
    parent.onChange();
  }
}

abstract class StorageContainer {
  String getString(String key, {String defaultValue}) => get(key, String, defaultValue);
  int getInteger(String key, {int defaultValue}) => get(key, int, defaultValue);
  double getDouble(String key, {double defaultValue}) => get(key, double, defaultValue);
  bool getBoolean(String key, {bool defaultValue}) => get(key, bool, defaultValue);
  List<dynamic> getList(String key, {List<dynamic> defaultValue}) => get(key, List, defaultValue);
  Map<dynamic, dynamic> getMap(String key, {Map<dynamic, dynamic> defaultValue}) => get(key, Map, defaultValue);
  
  dynamic getFromMap(String key, dynamic mapKey) => getMap(key)[mapKey];
  bool isInMap(String key, dynamic mapKey) => getMap(key).containsKey(mapKey);
  bool isInList(String key, dynamic value) => getList(key, defaultValue: []).contains(value);
  int getListLength(String key) => getList(key, defaultValue: []).length;
  
  int incrementInteger(String key, {int defaultValue: 0}) =>
      addToInteger(key, 1);
  
  int decrementInteger(String key, {int defaultValue: 0}) =>
      subtractFromInteger(key, 1);
  
  int addToInteger(String key, int n, {int defaultValue: 0}) {
    var v = getInteger(key, defaultValue: defaultValue);
    v += n;
    setInteger(key, v);
    return v;
  }
  
  int subtractFromInteger(String key, int n, {int defaultValue: 0}) {
    var v = getInteger(key, defaultValue: defaultValue);
    v -= n;
    setInteger(key, v);
    return v;
  }
  
  dynamic remove(String key) {
    var value = entries[key];
    entries.remove(key);
    onChange();
    return value;
  }
  
  void setString(String key, String value) => set(key, String, value);
  void setInteger(String key, int value) => set(key, int, value);
  void setBoolean(String key, bool value) => set(key, bool, value);
  void setDouble(String key, double value) => set(key, double, value);
  void setList(String key, List<dynamic> value) => set(key, List, value);
  void setMap(String key, Map<dynamic, dynamic> value) => set(key, Map, value);
  
  void addToList(String key, dynamic value) => setList(key, new List.from(getList(key))..add(value));
  void removeFromList(String key, dynamic value) => setList(key, new List.from(getList(key)..remove(value)));
  void putInMap(String key, dynamic mapKey, dynamic value) => setMap(key, new Map.from(get(key, Map, {}))..[mapKey] = value);
  void removeFromMap(String key, dynamic mapKey) => setMap(key, new Map.from(get(key, Map, {})..remove(mapKey)));
  
  List<String> getMapKeys(String key) => get(key, Map, {}).keys.toList();

  dynamic get(String key, Type type, dynamic defaultValue) {
    var mirror = reflectType(type);

    dynamic value = defaultValue;

    if (entries.containsKey(key)) {
      value = entries[key];
    }

    if (!mirror.isAssignableTo(reflectType(value != null ? value.runtimeType : Null))) {
      throw new Exception("ERROR: value is not the correct type.");
    }

    return value;
  }
  
  SubStorage getSubStorage(String key) {
    return new SubStorage(this, key);
  }

  void set(String key, Type type, value) {
    var mirror = reflectType(type);

    if (!mirror.isAssignableTo(reflectType(value != null ? value.runtimeType : Null))) {
      throw new Exception("ERROR: value is not the correct type.");
    }

    onChange();
    entries[key] = value;
  }
  
  List<String> get keys => entries.keys.toList();
  
  void onChange();
  Map<String, dynamic> get entries;
}
