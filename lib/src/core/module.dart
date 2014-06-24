part of yambot.core;

abstract class Module {
  /**
   * Module Name
   */
  String get name;

  /**
   * Initializes this Module
   */
  void init(YamBot bot);

  /**
   * Applies the Module to the IRC Client
   */
  void apply(IRC.Client client);
}

class CoreModule extends Module {
  YamBot bot;

  String name = "Core";

  @override
  void init(YamBot bot) {
    this.bot = bot;
  }

  @override
  void apply(IRC.Client client) {
    var prefix = bot.config.commands.prefix;

    client.register((IRC.ReadyEvent event) {
      bot.config.channels.forEach(event.join);
    });

    client.register((IRC.MessageEvent event) {
      if  (event.message.startsWith(prefix)) {
        var without_prefix = event.message.substring(prefix.length, event.message.length);
        var parts = without_prefix.split(" ");
        if (parts.length == 0) {
          return;
        }
        var command = parts[0];
        var args = new List.from(parts)
          ..removeAt(0);
        if (bot.config.commands.text.containsKey(command)) {
          if (args.length == 0) {
            event.reply(bot.config.commands.text[command]);
          } else if (args.length == 1) {
            event.reply("${args[0]}: ${bot.config.commands.text[command]}");
          }
        }
      }
    });
  }
}