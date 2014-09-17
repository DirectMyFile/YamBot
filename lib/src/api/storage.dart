part of polymorphic.api;

class Storage {
  final File file;
  
  Map<String, dynamic> json = {};
  
  bool _changed = true;
  
  Storage(this.file) {
    new Timer.periodic(new Duration(seconds: 1), (timer) {
      _save();
    });
  }
  
  void load() {
    if (!file.existsSync()) {
      return;
    }
    
    var content = file.readAsStringSync();
    json = JSON.decode(content);
  }
  
  void _save() {
    if (!_changed) return;
    file.writeAsStringSync(JSON.encode(json));
    _changed = false;
  }
  
  dynamic get(String key, [dynamic defaultValue]) => json.containsKey(key) ? json[key] : defaultValue;
  
  void set(String key, dynamic value) {
    json[key] = value;
    _changed = true;
  }
  
  Map<String, dynamic> get map => new Map.from(json);
}