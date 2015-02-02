import "package:polymorphic_bot/plugin.dart";
export "package:polymorphic_bot/plugin.dart";

@PluginInstance()
Plugin plugin;

@BotInstance()
BotConnector bot;

@RemoteMethod()
void sayHi(String network, String target) {
  bot.sendMessage(network, target, "Hello!");
}