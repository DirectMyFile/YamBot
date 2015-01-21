import "package:polymorphic_bot/api.dart";

@PluginInstance()
Plugin plugin;
@BotInstance()
BotConnector bot;
@PluginStorage("users")
Storage users;

main(args, port) => polymorphic(args, port);

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