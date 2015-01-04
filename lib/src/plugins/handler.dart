part of polymorphic.bot;

typedef PluginLoader PluginLoaderCreator();

class PluginLoadHelper {
  String name;
  String displayName;
  PluginLoaderCreator loader;
}

class PluginHandler {
  final CoreBot bot;

  PluginManager pm;
  PluginCommunicator _communicator;

  List<String> _elevatedPlugins = [];

  PluginHandler(this.bot) {
    pm = new PluginManager();
    _communicator = new PluginCommunicator(bot, this);
    _communicator.initialStart();
  }

  Future init() {
    return load().then((List<Plugin> plugins) {
      print("[Plugin Manager] Registered: ${plugins.join(", ")}");
      _communicator.handle();
      return plugins;
    });
  }
  
  List<String> _candidates = [];
  Map<String, List<String>> _requirements = <String, List<String>>{};
  Map<String, List<String>> _conflicts = <String, List<String>>{};
  
  Future load() {
    _elevatedPlugins.clear();
    _requirements.clear();
    _conflicts.clear();
    
    var pluginNames = <String>[];
    var pluginsDirectory = new Directory("plugins");
    if (!pluginsDirectory.existsSync()) pluginsDirectory.createSync();

    /* Patched loadAll() method */
    Future loadAll(Directory directory) {
      _candidates.clear();
      var loaders = <PluginLoadHelper>[];

      directory.listSync(followLinks: true).forEach((entity) {
        if (entity is! Directory) return;
        var packagesDirectory = new Directory("${entity.path}/packages");
        var pubspecFile = new File("${entity.path}/pubspec.yaml");
        Map<String, dynamic> pubspec = yaml.loadYaml(pubspecFile.readAsStringSync());

        var info = {
          "dependencies": [],
          "main": "main.dart",
          "update_dependencies": false,
          "elevated": false
        };

        if (pubspec["plugin"] != null) {
          info = pubspec["plugin"];
        }

        String pluginName = pubspec["name"];
        _candidates.add(pluginName);
        
        if (_disabled.contains(pluginName)) {
          return;
        }
        
        String displayName = pluginName;

        if (info.containsKey("display_name")) {
          displayName = info["display_name"];
        }

        if (info["elevated"] != null && info["elevated"]) {
          print("[Plugin Manager] ${pluginName} is elevated.");
          _elevatedPlugins.add(pluginName);
        }

        if (!packagesDirectory.existsSync() && pubspecFile.existsSync()) {
          /* Execute 'pub get' */
          print("[Plugin Manager] Fetching dependencies for plugin '${pluginName}'");
          var result = Process.runSync(Platform.isWindows ? "pub.bat" : "pub", ["get"], workingDirectory: entity.path);
          if (result.exitCode != 0) {
            print("[Plugin Manager] Failed to fetch dependencies for plugin '${pluginName}'");
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

        if (info['update_dependencies'] != null ? info['update_dependencies'] : false) {
          var result = Process.runSync(Platform.isWindows ? "pub.bat" : "pub", ["upgrade"], workingDirectory: entity.path);
          if (result.exitCode != 0) {
            print("[Plugin Manager] Failed to update dependencies for plugin '${pluginName}'");

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

        var loader = () => new BotPluginLoader(entity, info['main'] != null ? info['main'] : "main.dart");
        loaders.add(new PluginLoadHelper()
            ..name = pluginName
            ..loader = loader
            ..displayName = displayName);

        _requirements[pluginName] = new List<String>.from(info['dependencies'] == null ? [] : info['dependencies']);
        _conflicts[pluginName] = new List<String>.from(info['conflicts'] == null ? [] : info['conflicts']);

        pluginNames.add(pluginName);
      });

      /* Resolve Plugin Requirements */
      {
        print("[Plugin Manager] Resolving plugin requirements");
        for (var name in pluginNames) {
          List<String> requires = _requirements[name];
          requires.removeWhere((it) => pluginNames.contains(it));
          if (requires.isNotEmpty) {
            print("[Plugin Manager] Failed to resolve requirements for plugin '${name}'");
            var noun = requires.length == 1 ? "it" : "they";
            var verb = requires.length == 1 ? "was" : "were";
            print("[Plugin Manager] '${name}' requires '${requires.join(", ")}', but ${noun} ${verb} not found.");
            exit(1);
          }

          List<String> conflicting = _conflicts[name];
          conflicting.removeWhere((it) => !pluginNames.contains(it));

          if (conflicting.isNotEmpty) {
            print("[Plugin Manager] Failed to resolve conflicts for plugin '${name}'");
            var noun = requires.length == 1 ? "it" : "they";
            var verb = requires.length == 1 ? "is" : "are";
            print("[Plugin Manager] '${name}' conflicts with '${requires.join(", ")}', but ${noun} ${verb} installed.");
            exit(1);
          }
        }
      }

      var futures = [];

      loaders.forEach((loader) {
        futures.add(pm.load(loader.loader(), args: [loader.name, loader.displayName]));
      });

      return Future.wait(futures);
    }
    return loadAll(pluginsDirectory);
  }

  Future killPlugins() {
    pm.sendAll({
      "type": "event",
      "event": "shutdown"
    });

    return new Future.delayed(new Duration(milliseconds: 100)).then((_) {
      pm.killAll();
    });
  }

  Future disable(String name) {
    var requiredBy = _requirements.keys.where((it) {
      return _requirements[it].contains(name) && !_disabled.contains(it);
    }).toList();
    
    if (requiredBy.isNotEmpty) {
      throw new PluginDependencyException(name, requiredBy);
    }
    
    if (!_disabled.contains(name)) {
      _disabled.add(name);
    }
    
    return reloadPlugins();
  }
  
  Future enable(String name) {
    if (!_disabled.contains(name)) {
      return new Future.value();
    }
    
    var needed = _requirements[name].where((it) => _disabled.contains(it)).toList();
    
    if (needed.isNotEmpty) {
      throw new PluginDependencyException(name, needed);
    }
    
    _disabled.remove(name);
    
    return reloadPlugins();
  }

  List<String> _disabled = [];

  Future reloadPlugins() {
    return killPlugins().then((_) => init());
  }

  bool isPluginElevated(String plugin) {
    return _elevatedPlugins.contains(plugin);
  }
}

class BotPluginLoader extends PluginLoader {
  final String main;

  BotPluginLoader(Directory directory, [this.main = "main.dart"]) : super(directory);

  @override
  Future<Isolate> load(SendPort port, List<String> args) {
    args = args == null ? [] : args;

    var loc = path.joinAll([directory.absolute.path, main]);

    return Isolate.spawnUri(new Uri.file(loc), args, new Polymorphic.Plugin(args[0], args[1], port), packageRoot: new Uri.file(new Directory(directory.path + "/" + "packages").path)).then((isolate) {
      return isolate;
    });
  }
}

class PluginDependencyException {
  final String plugin;
  final List<String> dependencies;
  
  PluginDependencyException(this.plugin, this.dependencies);
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
