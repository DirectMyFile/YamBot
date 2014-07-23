part of bot;

class PluginHandler {

  final PluginManager pm = new PluginManager();
  final CoreBot bot;

  PluginCommunicator _handler;

  PluginHandler(this.bot) {
    _handler = new PluginCommunicator(pm, bot);
  }

  Future init() {
    return load().then((List<Plugin> plugins) {
      print("[Plugins] Registered: ${plugins.join(" ")}");
      _handler.handle();
      return plugins;
    });
  }

  Future load() {
    var dir = new Directory("plugins");
    if (!dir.existsSync()) dir.createSync();
    /* Patched Loader to Follow Symlinks */
    Future loadAll(Directory directory, [List<String> args]) {
      List<Future> futures = [];
      directory.listSync(followLinks: true).forEach((entity) {
        if (!(entity is Directory))
          return;
        var loader = new PluginLoader(entity);
        futures.add(pm.load(loader, args));
      });
      return Future.wait(futures);
    }
    return loadAll(dir);
  }
}

class VerificationManager {

  final String plugin;
  final Map data;

  /**
   * The type of command to execute, if any
   */
  String type;

  VerificationManager(this.plugin, this.data);

  dynamic operator [](String field) {
    return verify(field);
  }

  dynamic verify(String field) {
    var info = data[field];
    if (info == null) {
      if (type != null) {
        throw new Exception("$plugin is missing field '$field' when sending command '$type'");
      } else {
        throw new Exception("$plugin is missing field '$field'");
      }
    }
    return info;
  }
}
