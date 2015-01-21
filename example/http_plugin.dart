import "package:polymorphic_bot/api.dart";

main(args, port) => polymorphic(args, port);

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
