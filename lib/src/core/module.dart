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

    client.register((IRC.LineReceiveEvent event) {
      if (bot.config.output.console.raw) {
        print(">> ${event.line}");
      }
    });

    client.register((IRC.ErrorEvent event) {
      print(event.err);
      print(event.err.stackTrace);
      print(event.message);
      print(event.type);
      exit(1);
    });

    client.register((IRC.LineSentEvent event) {
      if (bot.config.output.console.raw) {
        print("<< ${event.line}");
      }
    });

    client.register((IRC.BotJoinEvent event) {
      if (bot.config.output.console.join) {
        print("Joined ${event.channel.name}");
      }
    });

    client.register((IRC.BotPartEvent event) {
      if (bot.config.output.console.part) {
        print("Left ${event.channel.name}");
      }
    });

    client.register((IRC.JoinEvent event) {
      if (bot.config.output.console.join) {
        print("<${event.channel.name}> ${event.user} joined the channel");
      }

      client.register((IRC.PartEvent event) {
        if (bot.config.output.console.part) {
          print("<${event.channel.name}> ${event.user} left the channel");
        }
      });
    });

    client.register((IRC.QuitEvent event) {
      if (bot.config.output.console.quit) {
        print("${event.user} quit");
      }
    });

    client.register((IRC.BotPartEvent event) {
      if (bot.config.output.console.part) {
        print("Left ${event.channel.name}");
      }
    });

    client.register((IRC.MessageEvent event) {
      if (bot.config.output.console.messages) {
        var buff = new StringBuffer("<");
        if (event.isPrivate) {
          buff
            ..write(event.from)
            ..write("> ");
        } else {
          buff
            ..write(event.target + ">")
            ..write("<${event.from}> ");
        }
        buff.write(event.message);
        print(buff.toString());
      }

      if (event.message.startsWith(prefix)) {
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