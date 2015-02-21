import "package:polymorphic_bot/plugin.dart";
export "package:polymorphic_bot/plugin.dart";

@PluginInstance()
Plugin plugin;
@BotInstance()
BotConnector bot;
@PluginStorage("users")
Storage users;

@Command("perist-me")
peristMe(event) {
  users.setBoolean(event.user, true);
  event.reply("> I have persisted ${event.user}!");
}

@Command("persisted")
persisted(event) {
  event.replyNotice("I have persisted ${users.keys.length} users.");
  event.replyNotice(users.keys.join(", "));
}