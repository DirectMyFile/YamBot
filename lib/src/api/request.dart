part of api;

typedef void RequestHandler(Request request);

class RequestAdapter {
  Map<String, RequestHandler> _handlers = {};
  
  RequestHandler register(String command, RequestHandler handler) => _handlers[command] = handler;
  
  void handle(Request request) {
    if (_handlers.containsKey(request.command)) {
      _handlers[request.command](request);
    }
  }
}