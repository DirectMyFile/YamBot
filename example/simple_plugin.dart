import "package:polymorphic_bot/api.dart";

BotConnector bot;

// Main Entry Point
// A Plugin instance is passed in. Plugin Communication is handled with your plugin instance.
void main(_, Plugin plugin) {
  // Gets the Bot Connector for your plugin.
  // The Bot Connector is what you use to communicate with the bot.
  bot = plugin.getBot();
  
  // Simple Hello Command
  bot.command("hello", (event) {
    // Sends the specified message to the channel that this command came from.
    event.reply("> Hello ${event.user}!");
  });
  
  // Handles Plugin Shutdowns
  plugin.onShutdown(() {
    // Do Something Important
  });
}
