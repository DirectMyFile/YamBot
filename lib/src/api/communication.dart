part of api;

class APIConnector {
  final Receiver conn;
  
  APIConnector(SendPort port) :
    conn = new Receiver(port);
  
  Future<Map<String, dynamic>> get(String command, [Map<String, dynamic> data]) {
    if (data == null) data = {};
    return conn.get(command, data);
  }
  
  Future<Map<String, dynamic>> get config =>
      get("config").then((response) => response["config"]);
  
  Future<Map<String, dynamic>> request(String plugin, String command, [Map<String, dynamic> data]) {
    return get("request", {
      "plugin": plugin,
      "command": command,
      "data": data
    });
  }
  
  void send(String command, Map<String, dynamic> data) {
    var request = {
      "command": command
    };
    request.addAll(data);
    conn.send(request);
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
}