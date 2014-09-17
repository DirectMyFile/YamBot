import "package:polymorphic_bot/api.dart";

BotConnector bot;
EventManager eventManager;
Storage userStorage;

// Main Entry Point
void main(_, port) {
  // Creates a Bot Connector for your plugin.
  // The Bot Connector is the central place for communication between your plugin and PolymorphicBot.
  bot = new BotConnector(port);
  
  // Creates a Storage Instance for your plugin.
  // The first argument is a group (usually your plugin name)
  // The second argument is the storage name
  userStorage = bot.createStorage("PersistentExample", "users");
  
  // Creates an Event Manager instance for your plugin.
  // The Event Manager is a core piece of the PolymorphicBot Plugin API.
  // You will use this to listen for events and register commands.
  eventManager = bot.createEventManager();
  
  // Persist Me Command
  eventManager.command("persist-me", (event) {
    userStorage.set(event.user, true);
    event.reply("> I have persisted ${event.user}!");
  });
  
  eventManager.command("persisted", (event) {
    var users = userStorage.map.keys;
    event.replyNotice("I have persisted ${users.length} users.");
    event.replyNotice(users.join(", "));
  });
}
