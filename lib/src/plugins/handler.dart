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
    _communicator._completer = new Completer();
    return load().then((List<Plugin> plugins) {
      BotMetrics.pluginsMetric.value = plugins.length.toDouble();
      print("[Plugin Manager] Registered: ${plugins.join(", ")}");
      _communicator.handle();
      
      if (plugins.isEmpty) {
        return null;
      }
      
      return _communicator._completer.future.then((_) { // Ensures Plugins are initialized.
        return plugins;
      });
    });
  }

  List<String> _candidates = [];
  Map<String, List<String>> _requirements = <String, List<String>>{};
  Map<String, List<String>> _conflicts = <String, List<String>>{};

  Future load() {
    _elevatedPlugins.clear();
    _requirements.clear();
    _communicator._initialized.clear();
    _conflicts.clear();

    var pluginNames = <String>[];
    var pluginsDirectory = new Directory("plugins");
    if (!pluginsDirectory.existsSync()) pluginsDirectory.createSync();

    /* Patched loadAll() method */
    Future loadAll(Directory directory) {
      _candidates.clear();
      var loaders = <PluginLoadHelper>[];

      var scriptDir = new Directory("scripts");

      if (!scriptDir.existsSync()) {
        scriptDir.createSync(recursive: true);
      }

      var entities = new List<FileSystemEntity>.from(directory.listSync(followLinks: true));
      entities.addAll(scriptDir.listSync(followLinks: true).where((it) => it is File));

      var pf = new Future.value();

      entities.forEach((entity) {
        pf = pf.then((_) {
          if (entity is File) {
            var name = entity.path.split("/").last;
            if (!name.endsWith(".dart")) {
              return new Future.value();
            }

            var pluginName = name.substring(0, name.length - ".dart".length);
            var content = entity.readAsStringSync();

            var unit = analyzer.parseDartFile(entity.path);
            var visitor = new ConstantValuesVisitor();

            unit.visitChildren(visitor);
            var data = visitor.values;
            var botDir = new File.fromUri(Platform.script).parent.parent;
            var deps = EnvironmentUtils.isCompiled() ? {
              "polymorphic_bot": {
                "git": "git://github.com/PolymorphicBot/PolymorphicBot.git"
              }
            } : {
              "polymorphic_bot": {
                "path": "${botDir.path}"
              }
            };

            String displayName;
            bool updateDependencies;
            List<String> conflicts;
            List<String> provides;

            dynamic findData(List<String> names, [dynamic defaultValue = null]) {
              var value = data[names.firstWhere((name) => data.containsKey(name), orElse: () => null)];
              if (value == null) {
                return defaultValue;
              } else {
                return value;
              }
            }

            pluginName = findData(["pluginName", "plugin_name", "PLUGIN_NAME"], pluginName);
            deps.addAll(findData(["dependencies", "DEPENDENCIES", "pluginDependencies", "pluginDeps", "deps", "plugin_dependencies"], {}));
            displayName = findData(["displayName", "pluginDisplayName", "plugin_display_name", "DISPLAY_NAME", "PLUGIN_DISPLAY_NAME"], pluginName);
            updateDependencies = findData(["updateDependencies", "update_dependencies", "runPubUpgrade", "UPDATE_DEPENDENCIES"], false);
            conflicts = findData(["PLUGIN_CONFLICTS", "conflicts", "CONFLICTS"], []);
            provides = findData(["PLUGIN_PROVIDES", "provides", "PROVIDES"], []);

            if (bot.config["ignore_scripts"] != null && bot.config["ignore_scripts"].contains(pluginName)) {
              return new Future.value();
            }

            var dir = new Directory(".plugins/${pluginName}");

            if (!dir.existsSync()) {
              dir.createSync(recursive: true);
            }

            var scriptFile = new File("${dir.path}/main.dart");
            scriptFile.writeAsStringSync(content);
            var pubspecFile = new File("${dir.path}/pubspec.yaml");
            String pubspec;

            pubspec = new JsonEncoder.withIndent("  ").convert({
              "name": pluginName,
              "dependencies": deps,
              "plugin": {
                "display_name": displayName,
                "update_dependencies": updateDependencies,
                "provides": provides,
                "conflicts": conflicts
              }
            });

            pubspecFile.writeAsStringSync(pubspec);
            entity = dir;
          }

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

          if (bot.config["plugins"] != null && bot.config["plugins"] is List && !bot.config["plugins"].contains(pluginName)) {
            return new Future.value();
          }

          _candidates.add(pluginName);

          if (_disabled.contains(pluginName)) {
            return new Future.value();
          }

          String displayName = pluginName;

          if (info.containsKey("display_name")) {
            displayName = info["display_name"];
          }

          if (info["elevated"] != null && info["elevated"]) {
            print("[Plugin Manager] ${pluginName} is elevated.");
            _elevatedPlugins.add(pluginName);
          }

          var depnames = pubspec["dependencies"].keys.where((it) {
            var x = pubspec["dependencies"][it];
            if (x is Map && x.containsKey("path")) {
              return false;
            }
            return true;
          }).toList();

          var f = new Future.value();

          if (!packagesDirectory.existsSync() || !depnames.every((it) => new Directory("${packagesDirectory.path}/${it}").existsSync())) {
            /* Execute 'pub get' */
            print("[Plugin Manager] Fetching dependencies for plugin '${pluginName}'");
            var buff = new StringBuffer();
            f = f.then((_) {
              return Process.start(Platform.isWindows ? "pub.bat" : "pub", ["get"], workingDirectory: entity.path);
            }).then((process) {
              process.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen((line) {
                buff.writeln(line);
              });
              
              process.stderr.transform(UTF8.decoder).transform(new LineSplitter()).listen((line) {
                buff.writeln(line);
              });
              
              return process.exitCode;
            }).then((code) {
              if (code != 0) {
                print("[Plugin Manager] Failed to fetch dependencies for plugin '${pluginName}'");
                for (var line in buff.toString().split("\n")) {
                  print(line);
                }
                exit(1);
              }
            });
          }

          if (info['update_dependencies'] != null ? info['update_dependencies'] : false) {
            print("[Plugin Manager] Updating dependencies for plugin '${pluginName}'");
            var buff = new StringBuffer();
            f = f.then((_) {
              return Process.start(Platform.isWindows ? "pub.bat" : "pub", ["upgrade"], workingDirectory: entity.path);
            }).then((process) {
              process.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen((line) {
                buff.writeln(line);
              });
              
              process.stderr.transform(UTF8.decoder).transform(new LineSplitter()).listen((line) {
                buff.writeln(line);
              });
              return process.exitCode;
            }).then((code) {
              if (code != 0) {
                print("[Plugin Manager] Failed to update dependencies for plugin '${pluginName}'");
                for (var line in buff.toString().split("\n")) {
                  print(line);
                }
                exit(1);
              }
            });
          }

          return f.then((_) {
            if (!_disabled.contains(pluginName)) {
              var loader = () => new BotPluginLoader(entity, info['main'] != null ? info['main'] : "main.dart");
              loaders.add(new PluginLoadHelper()
                  ..name = pluginName
                  ..loader = loader
                  ..displayName = displayName);
              pluginNames.add(pluginName);
            }

            _requirements[pluginName] = new List<String>.from(info['dependencies'] == null ? [] : info['dependencies']);
            _conflicts[pluginName] = new List<String>.from(info['conflicts'] == null ? [] : info['conflicts']);
          });
        });
      });

      return pf.then((_) {
        /* Resolve Plugin Requirements */
        {
          print("[Plugin Manager] Resolving Plugin Dependencies");

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
      });
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
    var stopwatch = new Stopwatch();
    stopwatch.start();
    return killPlugins().then((_) {
      return init();
    }).then((_) {
      stopwatch.stop();
      Globals.analytics.sendTiming("plugin reload", stopwatch.elapsedMilliseconds);
    });
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

    var loc = path.joinAll([directory.absolute.resolveSymbolicLinksSync(), main]);

    return Isolate.spawnUri(new Uri.file(loc), args, port, packageRoot: new Uri.file("${directory.path}/packages")).then((isolate) {
      return isolate;
    });
  }
}

class PluginDependencyException {
  final String plugin;
  final List<String> dependencies;

  PluginDependencyException(this.plugin, this.dependencies);

  @override
  String toString() => "${plugin} requires the plugins ${dependencies.join(', ')}";
}

class ConstantValuesVisitor extends analyzer.GeneralizingAstVisitor<Object> {
  final Map<String, dynamic> values = {};

  @override
  Object visitTopLevelVariableDeclaration(analyzer.TopLevelVariableDeclaration decl) {
    for (var v in decl.variables.variables) {
      if (v.initializer is analyzer.SimpleStringLiteral || v.initializer is analyzer.MapLiteral || v.initializer is analyzer.ListLiteral) {
        var n = v.name.name;
        var value;

        value = visitValue(v.initializer);

        values[n] = value;
      }
    }
    return null;
  }

  @override
  Object visitSimpleStringLiteral(analyzer.SimpleStringLiteral v) => v.value;

  @override
  Object visitMapLiteral(analyzer.MapLiteral literal) {
    var m = {};

    for (var e in literal.entries) {
      if (e.key is! analyzer.SimpleStringLiteral) {
        continue;
      }

      m[e.key.value] = visitValue(e.value);
    }

    return m;
  }

  @override
  Object visitListLiteral(analyzer.ListLiteral literal) {
    var l = [];

    for (var e in literal.elements) {
      l.add(visitValue(e));
    }

    return l;
  }

  dynamic visitValue(e) {
    if (e is analyzer.SimpleStringLiteral) {
      return e.value;
    } else if (e is analyzer.MapLiteral) {
      return visitMapLiteral(e);
    } else if (e is analyzer.ListLiteral) {
      return visitListLiteral(e);
    } else if (e is analyzer.BooleanLiteral) {
      return e.value;
    } else if (e is analyzer.NullLiteral) {
      return null;
    } else if (e is analyzer.IntegerLiteral) {
      return e.value;
    } else if (e is analyzer.DoubleLiteral) {
      return e.value;
    } else {
      return null;
    }
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
