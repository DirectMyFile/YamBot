import "package:polymorphic_bot/api.dart";

BotConnector bot;

// Main Entry Point
// A Plugin instance is passed in. Plugin Communication is handled with your plugin instance.
void main(_, Plugin plugin) {
  // Gets the Bot Connector for your plugin.
  // The Bot Connector is what you use to communicate with the bot.
  bot = plugin.getBot();
  
  // Adds a method that is remotely accessible.
  plugin.addRemoteMethod("greet", (call) {
    call.reply("Hello World");
  });
  
  // Calls another plugin's remote method.
  plugin.callRemoteMethod("SomePlugin", "sayHi", "Alex").then((result) {
    print(result);
  });
  
  // Add an advanced remote method.
  plugin.addRemoteMethod("doStuff", (call) {
    call.reply({
      "test": "Hello World"
    });
  });
  
  // Call an advanced remote method.
  plugin.callRemoteMethod("SomePlugin", "doStuff", {
    "something": "Hello World"
  }).then((result) {
    print(result["test"]);
  });
  
  // Handles Plugin Shutdowns
  plugin.onShutdown(() {
    // Do Something Important
  });
}
