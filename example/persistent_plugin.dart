import "package:polymorphic_bot/api.dart";

BotConnector bot;
Storage userStorage;

// Main Entry Point
void main(_, Plugin plugin) {
  // Gets the Bot Connector for your plugin.
  // The Bot Connector is the central place for communication between your plugin and PolymorphicBot.
  bot = plugin.getBot();
  
  // Creates a Storage Instance for your plugin.
  // The first argument is a group (usually your plugin name)
  // The second argument is the storage name
  userStorage = bot.createStorage("PersistentExample", "users");

  // Persist Me Command
  bot.command("persist-me", (event) {
    userStorage.set(event.user, true);
    event.reply("> I have persisted ${event.user}!");
  });
  
  bot.command("persisted", (event) {
    var users = userStorage.map.keys;
    event.replyNotice("I have persisted ${users.length} users.");
    event.replyNotice(users.join(", "));
  });
}
