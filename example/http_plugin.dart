import "package:polymorphic_bot/plugin.dart";
export "package:polymorphic_bot/plugin.dart";

@PluginInstance()
Plugin plugin;
@BotInstance()
BotConnector bot;

@HttpEndpoint("/")
httpRoot(request, response) {
  response.writeln("Hello World");
  response.close();
}

@WebSocketEndpoint("/ws")
wsEndpoint(socket) {
  WebSocketHelper.echo(socket);
}
