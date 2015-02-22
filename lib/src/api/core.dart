part of polymorphic.api;

/**
 * Action that runs when the plugin is ready.
 */
typedef void ReadyAction();

typedef void _SingleParameterFunction(a);
typedef void _TwoParameterFunction(a, b);

typedef void PluginEventHandler(String plugin, Map<String, dynamic> data);

Plugin polymorphic(List<String> args, SendPort port, {bool load: true}) {
  var plugin = new Plugin(args[0], args[1], port);

  if (load) {
    plugin.load();
  }

  return plugin;
}

class Plugin {
  /**
   * Plugin Name
   */
  final String name;

  /**
   * Plugin Display Name
   */
  final String displayName;
  final SendPort _port;

  /**
   * HTTP Client to use for your plugin.
   */
  http.Client httpClient;

  Plugin(this.name, this.displayName, this._port) {
    _createdPlugin = true;
  }

  Receiver _conn;
  List<StreamSubscription> _subs = [];
  StreamSubscription _eventSub;
  List<ShutdownAction> _shutdown = [];
  Map<String, StreamController> _controllers = {};
  List<Storage> _storages = [];
  Map<String, RemoteCallHandler> _methods = {};
  List<PluginEventHandler> _pluginEventHandlers = [];

  bool _isShutdown = false;

  /**
   * Pauses Plugin.
   */
  void disable() => _eventSub.pause();

  /**
   * Resumes Plugin.
   */
  void enable() => _eventSub.resume();

  /**
   * Gets an event stream for the event with the given [name].
   */
  Stream<Map<String, dynamic>> on(String name) {
    _init();

    if (!_controllers.containsKey(name)) {
      _controllers[name] = new StreamController.broadcast();
    }

    return _controllers[name].stream;
  }

  /**
   * Initializes the Plugin.
   */
  void load() {
    _init();
  }

  List<ReadyAction> _readyActions = [];
  List<ReadyAction> _pluginsReadyActions = [];

  /**
   * Calls [action] when the plugin is ready.
   */
  void onPluginReady(ReadyAction action) {
    _init();
    _readyActions.add(action);
  }

  /**
   * Calls [action] when all plugins are ready.
   */
  void onPluginsReady(ReadyAction action) {
    _pluginsReadyActions.add(action);
  }

  /**
   * Calls [action] when the plugin is shutting down.
   */
  void onShutdown(ShutdownAction action) {
    _init();

    _shutdown.add(action);
  }

  /**
   * Registers a subscription specified by [sub] to be canceled when the plugin is shutting down.
   */
  void registerSubscription(StreamSubscription sub) {
    _init();

    _subs.add(sub);
  }

  /**
   * Pipes the event given with [data] into event handlers as if it came from the bot.
   */
  void _handleEvent(Map<String, dynamic> data) {
    _init();

    if (_isShutdown) {
      return;
    }

    String name = data['event'];

    if (_controllers.containsKey(name)) _controllers[name].add(data);
  }

  /**
   * Gets a Plugin Interface for the given [plugin].
   */
  PluginInterface getPluginInterface(String plugin) {
    if (!_interfaces.containsKey(plugin)) {
      _interfaces[plugin] = new PluginInterface(this, plugin);
    }
    return _interfaces[plugin];
  }

  Map<String, PluginInterface> _interfaces = {};

  /**
   * Plugin HTTP Server.
   *
   * This will be null until [startHttpServer] is called.
   */
  HttpServer httpServer;

  List<PluginExceptionHandler> _exceptionHandlers = [];

  /**
   * Handles Exceptions.
   */
  void onException(PluginExceptionHandler handler) {
    _exceptionHandlers.add(handler);
  }

  /**
   * Initializes the Bot.
   */
  void _init() {
    if (_initCalled) {
      return;
    }

    _initCalled = true;
    _initTime = new DateTime.now().millisecondsSinceEpoch;

    if (httpClient == null) {
      httpClient = new http.Client();
    }

    if (_conn == null) {
      _conn = new Receiver(_port);

      _eventSub = _conn.listen((it) {
        if (it["exception"] != null) {
          var e = new PluginException(it["exception"]["message"]);
          if (_exceptionHandlers.isNotEmpty) {
            for (var handler in _exceptionHandlers) {
              handler(e);
            }
          } else {
            throw e;
          }
        }

        if (it["event"] != null) {
          _handleEvent(it);
        }
      });

      var sub;
      sub = on("shutdown").listen((_) {
        httpClient.close();
        for (var action in _shutdown) {
          action();
        }

        for (var controller in _controllers.values) {
          controller.close();
        }

        _eventSub.cancel();

        for (var s in _subs) {
          s.cancel();
        }

        for (var storage in _storages) {
          storage.destroy();
        }

        sub.cancel();

        _isShutdown = true;
      });

      registerSubscription(on("plugins-initialized").listen((event) {
        while (_pluginsReadyActions.isNotEmpty) {
          _pluginsReadyActions.removeAt(0)();
        }
      }));

      _conn.listenIntercom((plugin, data) {
        for (var handler in _pluginEventHandlers) {
          handler(plugin, data);
        }
      });

      _conn.listenRequest((request) {
        if (!request.command.startsWith("__") && _methods.containsKey(request.command)) {
          _methods[request.command](new RemoteCall(request));
        }

        if (request.command.startsWith("__")) {
          var name = request.command.substring(2);

          if (name == "getRemoteMethods") {
            request.reply({
              "value": _myMethods.values.map((it) {
                return {
                  "name": it.name,
                  "isVoid": it.isVoid
                };
              }).toList()
            });
          } else if (name == "getRegisteredCommands") {
            request.reply({
              "value": _bot._myCommands.map((command) {
                return {
                  "name": command.name,
                  "description": command.description,
                  "plugin": command.plugin,
                  "usage": command.usage
                };
              }).toList()
            });
          }
        }
      });
    }

    if (_bot == null) {
      _bot = new BotConnector(this);
    }

    on("initialize").listen((_) {
      /* Discover Annotations */
      List<FunctionAnnotation<Command>> cmds = findFunctionAnnotations(Command);
      List<FunctionAnnotation<EventHandler>> handlers = findFunctionAnnotations(EventHandler);
      Map<Type, Function> events = {
        OnJoin: getBot().onJoin,
        OnPart: getBot().onPart,
        OnBotJoin: getBot().onBotJoin,
        OnBotPart: getBot().onBotPart,
        OnMessage: getBot().onMessage,
        OnCTCP: getBot().onCTCP,
        OnNotice: getBot().onNotice,
        OnAction: getBot().onAction,
        OnQuit: getBot().onQuit,
        OnQuitPart: getBot().onQuitPart,
        OnBotReady: getBot().onReady,
        OnCommand: getBot().onCommand,
        OnKick: getBot().onKick,
        OnServerSupports: getBot().onServerSupports,
        OnMOTD: getBot().onMOTD,
        OnNickChange: getBot().onNickChange,
        OnNickInUse: getBot().onNickInUse,
        OnPluginsReady: onPluginsReady
      };

      for (var c in cmds) {
        var params = <String, Type>{};
        var rpc = 0;
        c.mirror.parameters.forEach((param) {
          if (!param.isOptional && !param.isNamed) {
            rpc++;
          }
          params[MirrorSystem.getName(param.simpleName)] = param.type.reflectedType;
        });

        if (rpc > 2) {
          throw new Exception("Command function '${MirrorSystem.getName(c.mirror.simpleName)}' from plugin '${name}' has an invalid number of arguments.");
        }

        var useInput = params.containsKey("input");
        bool hasEvent;

        if (rpc == 1 && params.containsKey("input")) {
          hasEvent = false;
        } else if (rpc == 2 && params.containsKey("input")) {
          hasEvent = true;
        } else if (rpc == 1) {
          hasEvent = true;
        } else if (params.isEmpty) {
          hasEvent = false;
        } else {
          throw new Exception("Command function '${MirrorSystem.getName(c.mirror.simpleName)}' from plugin '${name}' has an invalid command signature.");
        }

        var prefix;
        if (c.metadata.prefix != null && c.metadata.prefix is bool) {
          prefix = name;
        } else if (c.metadata.prefix != null && c.metadata.prefix is String) {
          prefix = c.metadata.prefix;
        } else if (c.metadata.prefix == null) {
        } else {
          throw new Exception("Command function '${MirrorSystem.getName(c.mirror.simpleName)}' from plugin '${name}' has an invalid prefix value.");
        }

        getBot().command(c.metadata.name, (CommandEvent e) {
          e._prefix = prefix;

          if (useInput) {
            return e.transform((input) {
              return c.function(hasEvent ? [e, input] : [input]);
            });
          } else if (params.isEmpty) {
            if (e.hasArguments) {
              e.usage();
              return null;
            }

            return c.invoke([]);
          } else {
            return c.invoke([e]);
          }
        }, permission: c.metadata.permission, usage: c.metadata.usage, description: c.metadata.description, allowVariables: c.metadata.allowVariables, randomize: c.metadata.randomize);
      }

      for (var handler in handlers) {
        EventHandler h = handler.metadata;
        var hasParam = handler.mirror.parameters.isNotEmpty;

        on(h.event).listen((e) {
          if (hasParam) {
            handler.invoke([e]);
          } else {
            handler.invoke([]);
          }
        });
      }

      var notifiers = findFunctionAnnotations(NotifyPlugin);

      for (var notifier in notifiers) {
        var plugin = notifier.metadata.plugin;
        onPluginsReady(() {
          var hasParam = notifier.mirror.parameters.where((it) => !it.isNamed && !it.isOptional).length == 1;
          var m = notifier.metadata.methods;
          PluginInterface interface;

          isPluginInstalled(plugin).then((isInstalled) {
            if (!isInstalled) {
              return null;
            }

            interface = getPluginInterface(plugin);

            if (m.isNotEmpty) {
              return interface.listMethods();
            } else {
              return [];
            }
          }).then((List<RemoteMethodInfo> methods) {
            if (methods == null) {
              return;
            }

            if (m.every((x) => methods.any((n) => n.name == x))) {
              notifier.invoke(hasParam ? [interface] : []);
            }
          });
        });
      }

      for (var type in events.keys) {
        var functions = findFunctionAnnotations(type);
        var vars = reflectClass(type).declarations.values.where((it) => it is VariableMirror && it.isFinal && !it.isStatic).toList();
        var map = <Symbol, dynamic>{};

        for (var x in functions) {
          var instance = reflect(x.metadata);
          for (var v in vars) {
            var i = instance.getField(v.simpleName);
            map[v.simpleName] = i.reflectee;
          }

          var hasParam = x.mirror.parameters.isNotEmpty;

          Function.apply(events[type], [hasParam ? (e) => x.invoke([e]) : (_) => x.invoke([])], map);
        }
      }

      for (FunctionAnnotation<RemoteMethod> a in findFunctionAnnotations(RemoteMethod)) {
        if (a.mirror.parameters.length == 1 && MirrorSystem.getName(a.mirror.parameters.first.simpleName) == "call") {
          addRemoteMethod(a.metadata.name != null ? a.metadata.name : MirrorSystem.getName(a.mirror.simpleName), (call) {
            a.invoke([call]);
          });
        } else {
          _addPluginMethod(this, currentMirrorSystem().isolate.rootLibrary, a.mirror);
        }
      }

      for (var variable in findVariablesAnnotation(PluginInstance)) {
        currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, this);
      }

      for (var variable in findVariablesAnnotation(BotInstance)) {
        currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, getBot());
      }

      for (var s in findFunctionAnnotations(Start)) {
        s.invoke([]);
      }

      for (var s in findFunctionAnnotations(Shutdown)) {
        onShutdown(() {
          s.invoke([]);
        });
      }

      for (var variable in findVariablesAnnotation(PluginStorage)) {
        PluginStorage m = variable.metadata.firstWhere((it) => it.type.isAssignableTo(reflectClass(PluginStorage))).reflectee;
        currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, getStorage(m.name, group: m.group, saveOnChange: m.saveOnChange));
      }

      var httpEndpoints = findFunctionAnnotations(HttpEndpoint);
      var websocketEndpoints = findFunctionAnnotations(WebSocketEndpoint);
      var defaultEndpoints = findFunctionAnnotations(DefaultEndpoint);

      if (defaultEndpoints.isNotEmpty && defaultEndpoints.length != 1) {
        throw new Exception("A plugin cannot have more than one default HTTP Endpoint.");
      }

      if (httpEndpoints.isNotEmpty || websocketEndpoints.isNotEmpty) {
        handleValue(HttpRequest request, value) {
          if (value == null) {
            request.response.close();
            return;
          }

          if (value is String) {
            request.response.write(value);
            request.response.close();
          } else if (value is Future) {
            value.then((v) => handleValue(request, v));
          } else if (value is ErrorResponse) {
            request.response.statusCode = value.statusCode;
            handleValue(request, value.content);
          } else if (value is File) {
            handleValue(request, value.readAsString());
          } else {
            request.response.writeln(jsonx.encode(value, indent: "  "));
            request.response.close();
          }
        }

        createHttpRouter().then((router) {
          for (var e in httpEndpoints) {
            var path = e.metadata.path;

            if (e.parameters.isEmpty) {
              router.addRoute(path, (req) {
                handleValue(req, e.invoke([]));
              });
            } else if (e.parameters.length == 1) {
              router.addRoute(path, (req) {
                handleValue(req, e.invoke([req]));
              });
            } else if (e.parameters.length == 2) {
              router.addRoute(path, (req) {
                handleValue(req, e.invoke([req, req.response]));
              });
            } else {
              throw new Exception("HTTP Endpoint has an invalid number of parameters");
            }
          }

          for (var e in websocketEndpoints) {
            var path = e.metadata.path;
            router.addWebSocketEndpoint(path, (socket) {
              e.invoke([socket]);
            });
          }

          if (defaultEndpoints.isNotEmpty) {
            var de = defaultEndpoints.first;

            if (de.parameters.length == 1) {
              router.defaultRoute((req) {
                handleValue(req, de.invoke([req]));
              });
            } else if (de.parameters.length == 2) {
              router.defaultRoute((req) {
                handleValue(req, de.invoke([req, req.response]));
              });
            } else {
              throw new Exception("Default HTTP Endpoint has an invalid number of parameters");
            }
          }
        });
      }

      callMethod("__initialized", true);

      for (var action in _readyActions) {
        action();
      }
    });
  }

  bool _initCalled = false;

  /**
   * Gets a Storage instance with the given name provided by [storageName].
   *
   * If [group] is provided it will be stored with that group.
   */
  Storage getStorage(String storageName, {String group, bool saveOnChange: true}) {
    _init();
    if (group == null) group = name;

    var file = new File("data/${group}/${storageName}.json").absolute;
    var existing = _storages.firstWhere((it) => it.path == file.path, orElse: () => null);

    if (existing != null) {
      return existing;
    }

    var storage = new Storage(file.path, saveOnChange: saveOnChange);
    storage.load();
    _storages.add(storage);
    return storage;
  }

  /**
   * Registers a method [name] to [handler].
   *
   * [metadata] is data to carry with the method.
   */
  void addRemoteMethod(String name, RemoteCallHandler handler, {Map<String, dynamic> metadata: const {}}) {
    _init();

    if (name.startsWith("__")) {
      log("WARNING: Remote methods starting with '__' are reserved for internal use. Not adding remote method.");
      return;
    }

    _methods[name] = handler;
    _myMethods[name] = new RemoteMethodInfo(name, metadata: metadata);
  }

  /**
   * Fetches Plugin Methods for the given [plugin].
   */
  Future<List<RemoteMethodInfo>> getRemoteMethods(String plugin) {
    return callRemoteMethod(plugin, "__getRemoteMethods").then((list) {
      return list.map((it) {
        return new RemoteMethodInfo(it["name"], isVoid: it["isVoid"]);
      }).toList();
    });
  }

  /**
   * Calls a Plugin Method.
   *
   * [plugin] is the target plugin.
   * [method] is the method name.
   * [arguments] are optional arguments.
   */
  Future<dynamic> callRemoteMethod(String plugin, String method, [dynamic arguments]) {
    var data = {
      "value": arguments
    };

    return callMethod("makePluginRequest", {
      "plugin": plugin,
      "command": method,
      "data": data
    });
  }

  /**
   * Handles Plugin Events.
   *
   * If [plugin] is provided the handler is called only for that plugin.
   */
  void onPluginEvent(PluginEventHandler handler, {String plugin}) {
    _init();

    _pluginEventHandlers.add((name, data) {
      if (plugin == null || name == plugin) {
        handler(name, data);
      }
    });
  }

  Future<Map<String, dynamic>> _get(String command, [Map<String, dynamic> data]) {
    _init();

    if (data == null) data = {};
    return _conn.get(command, data);
  }

  /**
   * Calls a Bot Method.
   *
   * [name] is the method name.
   * [arguments] is an optional argument.
   */
  Future<dynamic> callMethod(String name, [dynamic arguments]) {
    var data = {
      "value": arguments
    };

    return _get(name, data).then((response) {
      if (!response.containsKey("exception")) {
        return response["value"];
      } else {
        var e = new Exception(response["exception"]["message"]);
        throw e;
      }
    });
  }

  /**
   * Logs a Message to the Console.
   */
  void log(String message) {
    _init();

    print("[${displayName}] ${message}");
  }

  int _initTime;

  bool _isServerListening = false;

  /**
   * Starts an HTTP Server then create an HTTP Router.
   */
  Future<HttpRouter> createHttpRouter() {
    return startHttpServer().then((server) {
      return new HttpRouter(server);
    });
  }

  /**
   * Starts an HTTP Server that is forwarded through the main bot server.
   */
  Future<HttpServer> startHttpServer() {
    if (_isServerListening) {
      throw new Exception("Server is already listening.");
    }

    _isServerListening = true;

    return HttpServer.bind("0.0.0.0", 0).then((server) {
      httpServer = server;

      var startTime = new DateTime.now();
      if (startTime.millisecondsSinceEpoch - _initTime >= 5000) {
        callMethod("forwardHttpPort", server.port);
      } else {
        new Future.delayed(new Duration(seconds: 5), () {
          callMethod("forwardHttpPort", server.port);
        });
      }

      onShutdown(() {
        callMethod("unforwardHttpPort", {});
        server.close();
      });

      return server;
    });
  }

  /**
   * Checks if the plugin provided by [name] is installed.
   */
  Future<bool> isPluginInstalled(String name) => getPlugins().then((plugins) {
    return plugins.contains(name);
  });

  /**
   * Gets the loaded plugins.
   */
  Future<List<String>> getPlugins() {
    return callMethod("getPlugins");
  }

  /**
   * Sends [command] and [data] to a target.
   *
   * If [plugin] is provided it is sent to the given plugin otherwise it is sent to the main bot.
   */
  void send(String command, Map<String, dynamic> data, {String plugin}) {
    _init();

    var request = {
      "command": command
    };

    request.addAll(data);

    if (plugin != null) {
      _conn.intercom(plugin, request);
    } else {
      _conn.send(request);
    }
  }

  /**
   * Gets this plugin's bot instance.
   */
  BotConnector getBot() {
    _init();
    return _bot;
  }

  Map<String, RemoteMethodInfo> _myMethods = {};
}

class ErrorResponse {
  final int statusCode;
  final dynamic content;

  ErrorResponse(this.statusCode, this.content);
}

/**
 * A Handler for Plugin Exceptions
 */
typedef void PluginExceptionHandler(PluginException e);

/**
 * Wrapper for Plugin Exceptions
 */
class PluginException {
  final String message;

  PluginException(this.message);

  @override
  String toString() => message;
}
