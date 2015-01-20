part of polymorphic.api;

typedef void StorageChecker(Map<String, dynamic> content);

class Storage {
  final File file;
  
  List<StorageChecker> _checkers = [];

  Map<String, dynamic> _entries;
  Timer _timer;
  
  Storage(this.file);

  String getString(String key, {String defaultValue}) => get(key, String, defaultValue);
  int getInteger(String key, {int defaultValue}) => get(key, int, defaultValue);
  double getDouble(String key, {double defaultValue}) => get(key, double, defaultValue);
  bool getBoolean(String key, {bool defaultValue}) => get(key, bool, defaultValue);
  List<dynamic> getList(String key, {List<dynamic> defaultValue}) => get(key, List, defaultValue);
  Map<dynamic, dynamic> getMap(String key, {Map<dynamic, dynamic> defaultValue}) => get(key, Map, defaultValue);

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

    if (_entries.containsKey(key)) {
      value = _entries[key];
    }

    if (!mirror.isAssignableTo(reflectType(value != null ? value.runtimeType : Null))) {
      throw new Exception("ERROR: value is not the correct type.");
    }

    return value;
  }

  void set(String key, Type type, value) {
    var mirror = reflectType(type);

    if (!mirror.isAssignableTo(reflectType(value != null ? value.runtimeType : Null))) {
      throw new Exception("ERROR: value is not the correct type.");
    }

    _changed = true;
    _entries[key] = value;
  }
  
  bool _changed = false;

  void load() {
    if (!file.existsSync()) {
      _entries = {};
    } else {
      var content = file.readAsStringSync();
      var json = JSON.decode(content);

      for (var checker in _checkers) {
        checker(json);
      }

      _entries = json;
    }
  }

  void save() {
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    file.writeAsStringSync(new JsonEncoder.withIndent("  ").convert(_entries));
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
  
  List<String> get keys => _entries.keys.toList();
  Map<String, dynamic> asMap() => new Map.from(_entries);
  bool get isSaveTimerOn => _timer != null;
}
