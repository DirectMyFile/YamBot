import "package:polymorphic_bot/api.dart";

BotConnector bot;
Storage userStorage;

// Main Entry Point
// A Plugin instance is passed in. Plugin Communication is handled with your plugin instance.
void main(args, port) {
  var plugin = polymorphic(args, port);
  
  // Gets the Bot Connector for your plugin.
  // The Bot Connector is what you use to communicate with the bot.
  bot = plugin.getBot();
  
  // Creates a Storage Instance for your plugin.
  // The first argument is the storage name.
  userStorage = plugin.getStorage("users");

  // Persist Me Command
  bot.command("persist-me", (event) {
    userStorage.setBoolean(event.user, true);
    event.reply("> I have persisted ${event.user}!");
  });
  
  bot.command("persisted", (event) {
    var users = userStorage.keys;
    
    event.replyNotice("I have persisted ${users.length} users.");
    event.replyNotice(users.join(", "));
  });
}
