part of polymorphic.api;

class BotConnector {
  final Receiver conn;

  BotConnector(SendPort port) :
    conn = new Receiver(port);

  ConditionalFuture<Map<String, dynamic>> get(String command, [Map<String, dynamic> data]) {
    if (data == null) data = {};
    return conn.get(command, data);
  }

  Future<Map<String, dynamic>> getConfig() =>
      get("config").then((response) => response["config"]);

  @deprecated
  Future<Map<String, dynamic>> get config => getConfig();
  
  /**
   * [target] is where to send the message if the node is not matched.
   * [callback] is not called if the [user] has no permissions.
   */
  void permission(void callback(Map data), String network,
                          String target, String user, String node,
                          [bool notify]) {
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
      conn.intercom(plugin, data);
    } else {
      conn.send(request);
    }
  }

  StreamSubscription<Map<String, dynamic>> handleEvent(void handler(Map<String, dynamic> data)) => conn.listen(handler);

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
  
  EventManager createEventManager() => new EventManager(this);
  
  void handlePluginEvent(void handler(String plugin, Map<String, dynamic> data)) => conn.listenIntercom(handler);
}