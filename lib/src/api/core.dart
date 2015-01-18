part of polymorphic.api;

typedef void ReadyAction();

class BotConnector {
  final Plugin plugin;

  BotConnector(this.plugin);

  Future<Map<String, dynamic>> getConfig() => plugin.callMethod("getConfig");

  Future<Map<String, dynamic>> get config => getConfig();

  /**
   * [target] is where to send the message if the node is not matched.
   * [callback] is not called if the [user] has no permissions.
   */
  void checkPermission(void callback(Map data), String network, String target, String user, String node, [bool notify]) {
    Map params = {
      "node": node,
      "network": network,
      "user": user,
      "target": target,
      "notify": notify
    };

    plugin.callMethod("checkPermission", params).then((has) {
      if (has) {
        callback(has);
      }
    });
  }

  void onBotDetected(BotDetectionHandler handler, {String network}) {
    var sub = plugin.on("bot-detected").where((data) {
      if (network != null && network != data["network"]) return false;
      return true;
    }).listen((data) {
      var event = new BotDetectionEvent(this, data["network"], data["user"]);
    });

    plugin.registerSubscription(sub);
  }

  void mode(String network, String mode, {String user, String channel}) {
    plugin.callMethod("mode", {
      "network": network,
      "mode": mode,
      "user": user,
      "channel": channel
    });
  }

  void op(String network, String channel, String user) {
    mode(network, "+o", channel: channel, user: user);
  }

  void deop(String network, String channel, String user) {
    mode(network, "-o", channel: channel, user: user);
  }

  void voice(String network, String channel, String user) {
    mode(network, "+v", channel: channel, user: user);
  }

  void devoice(String network, String channel, String user) {
    mode(network, "-v", channel: channel, user: user);
  }

  void halfOp(String network, String channel, String user) {
    mode(network, "+h", channel: channel, user: user);
  }

  void dehalfOp(String network, String channel, String user) {
    mode(network, "-h", channel: channel, user: user);
  }

  void owner(String network, String channel, String user) {
    mode(network, "+q", channel: channel, user: user);
  }

  void deowner(String network, String channel, String user) {
    mode(network, "-q", channel: channel, user: user);
  }

  void quiet(String network, String channel, String user) {
    mode(network, "+q", channel: channel, user: user);
  }

  void unquiet(String network, String channel, String user) {
    mode(network, "-q", channel: channel, user: user);
  }

  void setTopic(String network, String channel, String topic) {
    getChannel(network, channel).then((channel) => channel.topic = topic);
  }

  void kick(String network, String channel, String user, {String reason}) {
    plugin.callMethod("kick", {
      "network": network,
      "channel": channel,
      "user": user,
      "reason": reason
    });
  }

  void ban(String network, String channel, String user) {
    mode(network, "+b", channel: channel, user: user);
  }

  void kickBan(String network, String channel, String user, {String reason}) {
    ban(network, channel, user);
    kick(network, channel, user, reason: reason);
  }

  void unban(String network, String channel, String user) {
    mode(network, "-b", channel: channel, user: user);
  }

  Future<UserInfo> getUserInfo(String network, String user) {
    return plugin.callMethod("whois", {
      "network": network,
      "user": user
    }).then((data) {
      return new UserInfo(this, network, data["nickname"],
                          data["username"], data["realname"], data["away"],
                          data["awayMessage"], data["isServerOperator"], data["hostname"],
                          data["idle"], data["idleTime"], data["memberIn"], data["operatorIn"],
                          data["voiceIn"], data["halfOpIn"], data["ownerIn"], data["channels"]);
    });
  }

  Future<Channel> getChannel(String network, String name) {
    return plugin.callMethod("getChannel", {
      "network": network,
      "channel": name
    }).then((data) {
      return new Channel(this, network, name, data["topic"], data["members"], data["ops"], data["voices"], data["halfops"], data["owners"]);
    });
  }

  void onReady(ReadyHandler handler, {String network}) {
    var sub = plugin.on("ready").where((data) {
      if (network != null) {
        return data["network"] == network;
      }
      return true;
    }).map((it) {
      var network = it["network"];

      return new ReadyEvent(this, network);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onNotice(NoticeHandler handler, {Pattern pattern}) {
    var sub = plugin.on("notice").where((data) {
      if (pattern != null) {
        return data['message'].allMatches(pattern).isNotEmpty;
      }
      return true;
    }).map((it) {
      var network = it["network"];
      var target = it["target"];
      var from = it["from"];
      var private = it["private"];
      var message = it["message"];

      return new NoticeEvent(this, network, target, from, private, message);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void sendMessage(String network, String target, String message) {
    plugin.callMethod("sendMessage", {
      "network": network,
      "message": message,
      "target": target
    });
  }

  void sendAction(String network, String target, String message) {
    plugin.callMethod("sendAction", {
      "network": network,
      "message": message,
      "target": target
    });
  }

  void joinChannel(String network, String channel) {
    plugin.callMethod("joinChannel", {
      "network": network,
      "channel": channel
    });
  }

  void partChannel(String network, String channel) {
    plugin.callMethod("partChannel", {
      "network": network,
      "channel": channel
    });
  }

  void sendRawLine(String network, String line) {
    plugin.callMethod("sendRawLine", {
      "network": network,
      "line": line
    });
  }

  Future<List<String>> getPlugins() {
    return plugin.getPlugins();
  }

  Future<List<String>> getNetworks() {
    return plugin.callMethod("getNetworks");
  }

  void sendNotice(String network, String target, String message) {
    plugin.callMethod("sendNotice", {
      "network": network,
      "message": message,
      "target": target
    });
  }

  void onMessage(MessageHandler handler, {Pattern pattern}) {
    var sub = plugin.on("message").where((data) {
      if (pattern != null) {
        return data['message'].allMatches(pattern).isNotEmpty;
      }
      return true;
    }).map((it) {
      var network = it["network"];
      var target = it["target"];
      var from = it["from"];
      var private = it["private"];
      var message = it["message"];

      return new MessageEvent(this, network, target, from, private, message);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  Future<bool> isUserABot(String network, String user) {
    return plugin.callMethod("isUserABot", {
      "network": network,
      "user": user
    });
  }

  Future<String> getPrefix(String network, String channel) {
    return plugin.callMethod("getPrefix", {
      "network": network,
      "channel": channel
    });
  }

  BotInterface getBotInterface(String network, String user) {
    return new BotInterface(this, network, user);
  }

  void onJoin(JoinHandler handler, {String channel, String user, String network}) {
    var sub = plugin.on("join").where((data) {
      bool matches = true;
      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      if (user != null && user != data["user"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String user = data['user'];
      String channel = data['channel'];

      var event = new JoinEvent(this, network, channel, user);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onPart(PartHandler handler, {String channel, String user, String network}) {
    var sub = plugin.on("part").where((data) {
      bool matches = true;
      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      if (user != null && user != data["user"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String user = data['user'];
      String channel = data['channel'];

      var event = new PartEvent(this, network, channel, user);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void reloadPlugins() {
    plugin.callMethod("reloadPlugins");
  }

  void stop() {
    plugin.callMethod("stop");
  }

  void clearBotMemory(String network) {
    plugin.callMethod("clearBotMemory", {
      "network": network
    });
  }

  void quit(String network, [String reason]) {
    plugin.callMethod("quit", {
      "network": network,
      "reason": reason
    });
  }

  void onBotJoin(BotJoinHandler handler, {String network, String channel}) {
    var sub = plugin.on("bot-join").where((data) {
      bool matches = true;

      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String channel = data['channel'];

      var event = new BotJoinEvent(this, network, channel);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onCTCP(CTCPHandler handler, {String network, String target, String message, String user}) {
    var sub = plugin.on("ctcp").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (target != null && target != data["target"]) matches = false;
      if (message != null && message != data["message"]) matches = false;
      if (user != null && user != data["user"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new CTCPEvent(this, data["network"], data["target"], data["user"], data["message"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onInvite(InviteHandler handler, {String network, String user, String channel}) {
    var sub = plugin.on("invite").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (user != null && user != data["user"]) matches = false;
      if (channel != null && channel != data["channel"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new InviteEvent(this, data["network"], data["user"], data["channel"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onConnect(ConnectHandler handler, {String network}) {
    var sub = plugin.on("connect").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new ConnectEvent(this, data["network"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onDisconnect(DisconnectHandler handler, {String network}) {
    var sub = plugin.on("disconnect").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new DisconnectEvent(this, data["network"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onChannelTopic(TopicHandler handler, {String network, String channel}) {
    var sub = plugin.on("topic").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (channel != null && channel != data["channel"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new TopicEvent(this, data["network"], data["user"], data["channel"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onMode(ModeHandler handler, {String network, String channel, String user, String mode}) {
    var sub = plugin.on("mode").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (user != null && user != data["user"]) matches = false;
      if (channel != null && channel != data["channel"]) matches = false;
      if (mode != null && mode != data["mode"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new ModeEvent(this, data["network"], data["channel"], data["user"], data["mode"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onBotPart(BotPartHandler handler, {String network, String channel}) {
    var sub = plugin.on("bot-part").where((data) {
      bool matches = true;

      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String channel = data['channel'];

      var event = new BotPartEvent(this, network, channel);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  Future<List<CommandInfo>> getCommands([String pluginName]) {
    return plugin.callMethod("getCommandInfo", pluginName != null ? {
      "plugin": pluginName
    } : {}).then((response) {
      if (response == null) {
        return null;
      }

      var infos = [];

      for (var key in response.keys) {
        var i = response[key];
        infos.add(new CommandInfo(i["plugin"], key, i["usage"], i["description"]));
      }

      return infos;
    });
  }

  List<CommandInfo> _myCommands = [];

  Future<bool> doesCommandExist(String name) {
    return plugin.callMethod("doesCommandExist", name);
  }

  Future<CommandInfo> getCommand(String name) {
    return plugin.callMethod("getCommandInfo", {
      "command": name
    }).then((response) {
      if (response == null) {
        return null;
      }

      var i = response;
      return new CommandInfo(i["plugin"], name, i["usage"], i["description"]);
    });
  }

  void command(String name, CommandHandler handler, {String usage: "", String description: "Not Provided", String permission}) {
    var info = new CommandInfo(plugin.name, name, usage, description);

    _myCommands.add(info);

    var sub = plugin.on("command").where((data) => data['command'] == name).listen((data) {
      var command = data['command'];
      var args = data['args'];
      var user = data['from'];
      var channel = data['target'];
      var network = data['network'];
      var message = data['message'];

      var event = new CommandEvent(this, network, command, message, user, channel, args);

      if (permission != null) {
        event.require(permission, () {
          handler(event);
        });
      } else {
        handler(event);
      }
    });

    plugin.registerSubscription(sub);
  }

  void sendCTCP(String network, String target, String msg) {
    plugin.callMethod("sendCTCP", {
      "network": network,
      "target": target,
      "message": msg
    });
  }
}

typedef void PluginEventHandler(String plugin, Map<String, dynamic> data);

class Plugin {
  final String name;
  final String displayName;
  final SendPort _port;

  http.Client httpClient;

  Plugin(this.name, this.displayName, this._port);

  Receiver _conn;
  BotConnector _bot;
  List<StreamSubscription> _subs = [];
  StreamSubscription _eventSub;
  List<ShutdownAction> _shutdown = [];
  Map<String, StreamController> _controllers = {};
  List<Storage> _storages = [];
  Map<String, RemoteCallHandler> _methods = {};
  List<PluginEventHandler> _pluginEventHandlers = [];

  bool _isShutdown = false;

  void disable() => _eventSub.pause();
  void enable() => _eventSub.resume();

  Stream<Map<String, dynamic>> on(String name) {
    _init();

    if (!_controllers.containsKey(name)) {
      _controllers[name] = new StreamController.broadcast();
    }

    return _controllers[name].stream;
  }
  
  void load() {
    _init();
  }

  List<ReadyAction> _readyActions = [];

  void onPluginReady(ReadyAction action) {
    _init();
    _readyActions.add(action);
  }

  void onShutdown(ShutdownAction action) {
    _init();

    _shutdown.add(action);
  }

  void registerSubscription(StreamSubscription sub) {
    _init();

    _subs.add(sub);
  }

  void _handleEvent(Map<String, dynamic> data) {
    _init();

    if (_isShutdown) {
      return;
    }

    String name = data['event'];

    if (_controllers.containsKey(name)) _controllers[name].add(data);
  }

  PluginInterface getPluginInterface(String plugin) {
    if (!_interfaces.containsKey(plugin)) {
      _interfaces[plugin] = new PluginInterface(this, plugin);
    }
    return _interfaces[plugin];
  }

  Map<String, PluginInterface> _interfaces = {};

  HttpServer httpServer;

  List<PluginExceptionHandler> _exceptionHandlers = [];

  void onException(PluginExceptionHandler handler) {
    _exceptionHandlers.add(handler);
  }

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

        sub.cancel();

        _isShutdown = true;
      });

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
              "value": _myMethods.values
            });
          } else if (name == "getRegisteredCommands") {
            request.reply({
              "value": _bot._myCommands
            });
          }
        }
      });
    }

    if (_bot == null) {
      _bot = new BotConnector(this);
    }

    for (var action in _readyActions) {
      action();
    }
    
    /* Discover Annotations */
    List<FunctionAnnotation<Command>> cmds = findFunctionAnnotations(Command);
    List<FunctionAnnotation<EventHandler>> handlers = findFunctionAnnotations(EventHandler);
    Map<Type, Function> events = {
      OnJoin: getBot().onJoin,
      OnPart: getBot().onPart,
      OnBotJoin: getBot().onBotJoin,
      OnBotPart: getBot().onBotPart,
      OnMessage: getBot().onMessage
    };
    
    for (var c in cmds) {
      getBot().command(c.metadata.name, c.function, permission: c.metadata.permission);
    }
    
    for (var handler in handlers) {
      EventHandler h = handler.metadata;
      on(h.event).listen(handler.function);
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
        
        Function.apply(events[type], [x.function], map);
      }
    }
    
    for (FunctionAnnotation<RemoteMethod> a in findFunctionAnnotations(RemoteMethod)) {
      addRemoteMethod(a.metadata.name != null ? a.metadata.name : MirrorSystem.getName(a.mirror.simpleName), a.function);
    }
    
    for (var variable in findVariablesAnnotation(PluginInstance)) {
      currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, this);
    }
    
    for (var s in findFunctionAnnotations(Start)) {
      s.function();
    }
    
    for (var variable in findVariablesAnnotation(BotInstance)) {
      currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, getBot());
    }

    callMethod("__initialized", true);
  }

  bool _initCalled = false;

  Storage getStorage(String storageName, {String group}) {
    _init();

    if (group == null) group = name;

    var file = new File("data/${group}/${storageName}.json");

    var storage = new Storage(file);
    storage.load();
    _storages.add(storage);
    return storage;
  }

  void addRemoteMethod(String name, RemoteCallHandler handler, {Map<String, dynamic> metadata: const {}}) {
    _init();

    if (name.startsWith("__")) {
      log("WARNING: Remote methods starting with '__' are reserved for internal use. Not adding remote method.");
      return;
    }

    _methods[name] = handler;
    _myMethods[name] = new RemoteMethodInfo(name, metadata: metadata);
  }

  Future<List<RemoteMethodInfo>> getRemoteMethods(String plugin) {
    return callRemoteMethod(plugin, "__getRemoteMethods");
  }

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

  void log(String message) {
    _init();

    print("[${displayName}] ${message}");
  }

  int _initTime;

  bool _isServerListening = false;

  Future<HttpRouter> createHttpRouter() {
    return startHttpServer().then((server) {
      return new HttpRouter(server);
    });
  }

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

  Future<bool> isPluginInstalled(String name) => getPlugins().then((plugins) {
    return plugins.contains(name);
  });

  Future<List<String>> getPlugins() {
    return callMethod("getPlugins");
  }

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

  BotConnector getBot() {
    _init();
    return _bot;
  }

  Map<String, RemoteMethodInfo> _myMethods = {};
}

typedef void PluginExceptionHandler(PluginException e);

class PluginException {
  final String message;

  PluginException(this.message);

  @override
  String toString() => message;
}
