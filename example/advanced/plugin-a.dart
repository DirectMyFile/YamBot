import "package:polymorphic_bot/plugin.dart";
export "package:polymorphic_bot/plugin.dart";

@PluginInstance()
Plugin plugin;

@BotInstance()
BotConnector bot;

PluginInterface b;

@Start()
load() {
  b = plugin.getPluginInterface("b");
}

@Command("run-hello")
hello(event) {
  b.sayHello(network: event.network, target: event.channel);
}
