part of polymorphic.api;

class BotConnector {
  final Receiver conn;

  BotConnector(SendPort port) : conn = new Receiver(port) {
    _eventSub = conn.listen((it) {
      handleEvent(it);
    });
    var sub;
    sub = on("shutdown").listen((_) {
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

      for (var storage in _storages) {
        storage.destroy();
      }

      _isShutdown = true;
    });
  }

  ConditionalFuture<Map<String, dynamic>> get(String command, [Map<String, dynamic> data]) {
    if (data == null) data = {};
    return conn.get(command, data);
  }

  Future<Map<String, dynamic>> getConfig() => get("config").then((response) => response["config"]);

  Future<Map<String, dynamic>> get config => getConfig();

  /**
   * [target] is where to send the message if the node is not matched.
   * [callback] is not called if the [user] has no permissions.
   */
  void permission(void callback(Map data), String network, String target, String user, String node, [bool notify]) {
    Map params = {
      "node": node,
      "network": network,
      "nick": user,
      "target": target,
      "notify": notify
    };
    conn.get("permission", params).callIf((data) => data['has']).then(callback);
  }

  void send(String command, Map<String, dynamic> data, {String plugin}) {
    var request = {
      "command": command
    };

    request.addAll(data);

    if (plugin != null) {
      conn.intercom(plugin, request);
    } else {
      conn.send(request);
    }
  }

  void handleRequest(void handler(Request request)) => conn.listenRequest(handler);

  void message(String network, String target, String message) {
    send("message", {
      "network": network,
      "message": message,
      "target": target
    });
  }

  Future<List<String>> getPlugins() {
    return get("plugins").then((data) => data['plugins']);
  }

  Future<List<String>> getNetworks() {
    return get("networks").then((data) => data['networks']);
  }

  void notice(String network, String target, String message) {
    send("notice", {
      "network": network,
      "message": message,
      "target": target
    });
  }

  List<Storage> _storages = [];

  Storage createStorage(String group, String name) {
    var file = new File("data/${group}/${name}.json");
    file.parent.createSync(recursive: true);

    var storage = new Storage(file);
    _storages.add(storage);
    return storage;
  }

  List<StreamSubscription> _subs = [];
  StreamSubscription _eventSub;
  List<ShutdownAction> _shutdown = [];
  final Map<String, StreamController> _controllers = {};

  bool _isShutdown = false;

  void disable() => _eventSub.pause();
  void enable() => _eventSub.resume();

  Stream<Map<String, dynamic>> on(String name) {
    if (!_controllers.containsKey(name)) {
      _controllers[name] = new StreamController.broadcast();
    }

    return _controllers[name].stream;
  }

  void onMessage(MessageHandler handler, {Pattern pattern}) {
    var sub = on("message").map((it) {
      var network = it["network"];
      var target = it["target"];
      var from = it["from"];
      var private = it["private"];
      var message = it["message"];

      return new MessageEvent(this, network, target, from, private, message);
    }).where((MessageEvent it) {
      if (pattern != null) {
        return it.message.allMatches(pattern).isNotEmpty;
      }
      return true;
    }).listen((event) {
      handler(event);
    });

    _subs.add(sub);
  }

  void command(String name, CommandHandler handler) {
    var sub = on("command").where((data) => data['command'] == name).listen((data) {
      var command = data['command'];
      var args = data['args'];
      var user = data['from'];
      var channel = data['target'];
      var network = data['network'];
      var message = data['message'];

      handler(new CommandEvent(this, network, command, message, user, channel, args));
    });

    _subs.add(sub);
  }

  void onShutdown(void action()) {
    _shutdown.add(action);
  }

  void registerSubscription(StreamSubscription sub) {
    _subs.add(sub);
  }

  void handleEvent(Map<String, dynamic> data) {
    if (_isShutdown) {
      return;
    }

    String name = data['event'];

    if (_controllers.containsKey(name)) _controllers[name].add(data);
  }

  void handlePluginEvent(void handler(String plugin, Map<String, dynamic> data)) => conn.listenIntercom(handler);
}

class Plugin {
  final String name;
  final SendPort port;

  BotConnector _bot;

  Plugin(this.name, this.port);

  void _init() {
    if (_bot == null) {
      _bot = new BotConnector(port);
    }
  }

  BotConnector getBot() {
    _init();
    return _bot;
  }
}
