part of polymorphic.utils;

class HttpHelper {
  static HttpClient client = new HttpClient();
  
  static void forward(HttpRequest request, String newPath, String host, int port) {
    var response = request.response;
    client.open(request.method, host, port, newPath).then((req) {
      var completer = new Completer();
      
      request.listen((data) {
        req.add(data);
      }).onDone(() {
        request.cookies.addAll(req.cookies);
        request.headers.forEach((name, value) {
          for (var v in value) {
            req.headers.add(name, v);
          }
        });
        completer.complete(req.close());
      });
      
      return completer.future;
    }).then((HttpClientResponse res) {
      res.listen((data) {
        response.add(data);
      });
      
      response.cookies.addAll(res.cookies);
      res.headers.forEach((name, value) {
        for (var v in value) {
          response.headers.add(name, v);
        }
      });
      
      response.statusCode = res.statusCode;
      
      return response.close();
    });
  }
}