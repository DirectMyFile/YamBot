import "package:polymorphic_bot/api.dart";

main(args, port) => polymorphic(args, port);

@PluginInstance()
Plugin plugin;
@BotInstance()
BotConnector bot;

@Start()
start() {
  // Starts an HTTP Server and routes it through Polymorphic's root HTTP Server.
  // This then creates an HTTP Router.
  plugin.createHttpRouter().then((router) {
    // Route requests to / to this method.
    router.addRoute("/", (request) {
      request.response.writeln("Hello World");
      request.response.close();
    });
    
    // You can even handle WebSockets!
    router.addWebSocketEndpoint("/ws", (socket) {
      WebSocketHelper.echo(socket);
    });
  });
}