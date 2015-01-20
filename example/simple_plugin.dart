import "package:polymorphic_bot/api.dart";

@PluginInstance()
Plugin plugin;

@BotInstance()
BotConnector bot;

void main(_, Plugin plugin) => plugin.load();

@Command("hello")
hello(CommandEvent event) => event.reply("> Hello World");