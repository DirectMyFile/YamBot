part of polymorphic.api;

class HttpRouter {
  final List<HttpRoute> routes = [];
  final HttpServer server;

  HttpRouter(this.server) {
    server.listen((request) {
      handleRequest(request);
    });
    
    _defaultHandler = notFound;
  }

  void addRoute(dynamic pattern, HttpRequestHandler handler, {String method}) {
    if (pattern is! String && pattern is! RegExp) {
      throw new Exception("pattern must be a string or regexp");
    }

    var route = new HttpRoute(pattern, handler, method);
    routes.add(route);
  }

  HttpRequestHandler _defaultHandler;
  
  void notFound(HttpRequest request) {
    HttpHelper.notFound(request);
  }

  void defaultRoute(HttpRequestHandler handler) {
    _defaultHandler = handler;
  }

  void addWebSocketEndpoint(String path, WebSocketHandler handler) {
    addRoute(path, (request) {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.BAD_REQUEST;
        request.response.writeln("ERROR: This is a WebSocket endpoint.");
        request.response.close();
        return;
      }

      WebSocketTransformer.upgrade(request).then(handler);
    });
  }

  void handleRequest(HttpRequest request) {
    var path = request.uri.path;

    for (var route in routes) {
      var pattern = route.pattern;

      var matches = false;
      if (pattern is String) {
        matches = pattern == path;
      } else if (pattern is RegExp) {
        matches = pattern.hasMatch(path);
      } else {
        throw new Exception("Invalid Pattern Type");
      }

      if (matches && (route.method != null ? route.method == request.method : true)) {
        route.handler(request);
        return;
      }
    }

    _defaultHandler(request);
  }
}

class HttpRoute {
  final dynamic pattern;
  final HttpRequestHandler handler;
  final String method;

  HttpRoute(this.pattern, this.handler, this.method);
}

class HttpError {
  final String message;
  final int statusCode;
  final String response;

  HttpError(this.message, this.statusCode, this.response);
}

typedef void HttpRequestHandler(HttpRequest request);
typedef void WebSocketHandler(WebSocket socket);
