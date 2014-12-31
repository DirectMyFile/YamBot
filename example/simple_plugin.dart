import "package:polymorphic_bot/api.dart";

BotConnector bot;

// Main Entry Point
void main(_, port) {
  // Creates a Bot Connector for your plugin.
  // The Bot Connector is the central place for communication between your plugin and PolymorphicBot.
  bot = new BotConnector(port);
  
  // Simple Hello Command
  bot.command("hello", (event) {
    // Sends the specified message to the channel that this command came from.
    event.reply("> Hello ${event.user}!");
  });
  
  // Handles Plugin Shutdowns
  bot.onShutdown(() {
    // Do Something Important
  });
}
