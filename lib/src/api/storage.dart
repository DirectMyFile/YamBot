part of polymorphic.api;

class Storage {
  final File file;

  Map<String, dynamic> json = {};

  bool _changed = true;
  final bool pretty;

  Timer _saveTimer;

  Storage(this.file, {this.pretty: true}) {
    _saveTimer = new Timer.periodic(new Duration(seconds: 2), (timer) {
      _save();
    });
  }

  void load() {
    if (!file.existsSync()) {
      return;
    }

    var content = file.readAsStringSync().trim();
    json = JSON.decode(content);
  }

  void _save() {
    if (!_changed) return;
    _changed = false;
    var encoder = pretty ? new JsonEncoder.withIndent("  ") : JSON.encoder;
    file.writeAsStringSync(encoder.convert(json));
  }

  dynamic get(String key, [dynamic defaultValue]) => json.containsKey(key) ? json[key] : defaultValue;

  void set(String key, dynamic value) {
    json[key] = value;
    _changed = true;
  }

  void destroy() {
    _saveTimer.cancel();
  }

  Map<String, dynamic> get map => new Map.from(json);
}
