part of polymorphic.bot;

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
    var requirements = {};
    var plugin_names = [];
    var dir = new Directory("plugins");
    if (!dir.existsSync()) dir.createSync();
    
    /* Patched loadAll() method */
    Future loadAll(Directory directory) {
      var loaders = [];
      
      directory.listSync(followLinks: true).forEach((entity) {
        if (!(entity is Directory))
          return;
        var packages_dir = new Directory("${entity.path}/packages");
        var pubspec = new File("${entity.path}/pubspec.yaml");
        
        
        if (!packages_dir.existsSync() && pubspec.existsSync()) {
          /* Execute 'pub get' */
          var spec = yaml.loadYaml(pubspec.readAsStringSync());
          var plugin_name = spec["name"] as String;
          print("[Plugins] Fetching Dependencies for Plugin '${plugin_name}'");
          var result = Process.runSync("pub", ["get"], workingDirectory: entity.path);
          if (result.exitCode != 0) {
            print("[Plugins] Failed to Fetch Dependencies for Plugin '${plugin_name}'");
            if (result.stdout.trim() != "") {
              print("[STDOUT]");
              stdout.write(result.stdout);
            }
            if (result.stderr.trim() != "") {
              print("[STDERR]");
              stdout.write(result.stderr); 
            }
            exit(1);
          }
        }
        
        var loader = () => new PluginLoader(entity);
        loaders.add(loader);
        
        var spec = yaml.loadYaml(pubspec.readAsStringSync());
        
        if (spec.containsKey("requires")) {
          requirements[spec["name"]] = new List.from(spec['requires']);
        } else {
          requirements[spec["name"]] = [];
        }
        
        plugin_names.add(spec["name"]);
      });
      
      /* Resolve Plugin Requirements */
      {
        print("[Plugins] Resolving Plugin Requirements");
        for (var name in plugin_names) {
          var requires = requirements[name];
          requires.removeWhere((it) => plugin_names.contains(it));
          if (requires.length != 0) {
            print("[Plugins] Failed to resolve requirements for plugin '${name}'");
            var noun = requires.length == 1 ? "it" : "they";
            var verb = requires.length == 1 ? "was" : "were";
            print("[Plugins] '${name}' requires '${requires.join(", ")}', but ${noun} ${verb} not found");
            exit(1);
          }
        }
      }
      
      var futures = [];
      
      loaders.forEach((loader) {
        futures.add(pm.load(loader()));
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
