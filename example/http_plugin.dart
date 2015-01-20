import "package:polymorphic_bot/api.dart";

BotConnector bot;

// Main Entry Point
// A Plugin instance is passed in. Plugin Communication is handled with your plugin instance.
void main(args, port) {
  var plugin = polymorphic(args, port);
  
  // Gets the Bot Connector for your plugin.
  // The Bot Connector is what you use to communicate with the bot.
  bot = plugin.getBot();
  
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
  
  // Handles Plugin Shutdowns
  plugin.onShutdown(() {
    // Do Something Important
  });
}
