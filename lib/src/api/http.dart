part of polymorphic.api;

class HttpRouter {
  final List<HttpRoute> routes = [];
  final HttpServer server;
  
  HttpRouter(this.server) {
    server.listen((request) {
      handleRequest(request);
    });
  }
  
  void addRoute(String pattern, HttpRequestHandler handler, {String method}) {
    var route = new HttpRoute(pattern, handler, method);
    routes.add(route);
  }
  
  HttpRequestHandler _defaultHandler = (HttpRequest request) {
    var response = request.response;
    response.statusCode = 404;
    response.writeln("ERROR: Not Found.");
    response.close();
  };
  
  void defaultRoute(HttpRequestHandler handler) {
    _defaultHandler = handler;
  }
  
  void handleRequest(HttpRequest request) {
    var path = request.uri.path;
    
    for (var route in routes) {
      var glob = new Glob(route.pattern);
      if (glob.hasMatch(path) && (route.method != null ? route.method == request.method : true)) {
        route.handler(request);
        return;
      }
    }
    
    _defaultHandler(request);
  }
}

class HttpRoute {
  final String pattern;
  final HttpRequestHandler handler;
  final String method;
  
  HttpRoute(this.pattern, this.handler, this.method);
}

typedef void HttpRequestHandler(HttpRequest request);