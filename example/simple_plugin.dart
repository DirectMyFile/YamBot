import "package:polymorphic_bot/api.dart";

BotConnector bot;
EventManager eventManager;

// Main Entry Point
void main(_, port) {
  // Creates a Bot Connector for your plugin.
  // The Bot Connector is the central place for communication between your plugin and PolymorphicBot.
  bot = new BotConnector(port);
  
  // Creates an Event Manager instance for your plugin.
  // The Event Manager is a core piece of the PolymorphicBot Plugin API.
  // You will use this to listen for events and register commands.
  eventManager = bot.createEventManager();
  
  // Simple Hello Command
  eventManager.command("hello", (event) {
    // Sends the specified message to the channel that this command came from.
    event.reply("> Hello ${event.user}!");
  });
  
  // Handles Plugin Shutdowns
  eventManager.onShutdown(() {
    // Do Something Important
  });
}
