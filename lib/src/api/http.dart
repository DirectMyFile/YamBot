part of polymorphic.api;

class HttpRouter {
  final List<HttpRoute> routes = [];
  final HttpServer server;
  
  HttpRouter(this.server) {
    server.listen((request) {
      handleRequest(request);
    });
  }
  
  void addRoute(dynamic pattern, HttpRequestHandler handler, {String method}) {
    if (pattern is! String && pattern is! RegExp) {
      throw new Exception("pattern must be a string or regexp");
    }
    
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
      var pattern = route.pattern;
      
      var matches = false;
      if (pattern is String) {
        matches = pattern == path;        
      } else if (pattern is RegExp) {
        matches = pattern.hasMatch(path);
      } else {
        throw new Exception("Invalid Pattern Type");
      }
      
      if (route.pattern.allMatches(path).isNotEmpty && (route.method != null ? route.method == request.method : true)) {
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

typedef void HttpRequestHandler(HttpRequest request);