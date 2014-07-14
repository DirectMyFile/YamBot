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

  String get name => "Core";

  @override
  void init(YamBot bot) {
    this.bot = bot;
  }

  @override
  void apply(IRC.Client client) {
    var prefix = bot.config.commands.prefix;

    var config = bot.config;

    client.register((IRC.ConnectEvent event) {
      if (config.output.console.connect) {
        print("Connected");
      }
    });

    client.register((IRC.DisconnectEvent event) {
      if (config.output.console.disconnect) {
        print("Disconnected");
      }
    });

    client.register((IRC.ReadyEvent event) {
      if (config.output.console.ready) {
        print("Bot is Ready");
      }
      config.channels.forEach(event.join);
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
      if (config.output.console.raw) {
        print("<< ${event.line}");
      }
    });

    client.register((IRC.BotJoinEvent event) {
      if (config.output.console.join) {
        print("Joined ${event.channel.name}");
      }
    });

    client.register((IRC.BotPartEvent event) {
      if (config.output.console.part) {
        print("Left ${event.channel.name}");
      }
    });

    client.register((IRC.JoinEvent event) {
      if (config.output.console.join) {
        print("<${event.channel.name}> ${event.user} joined the channel");
      }

      client.register((IRC.PartEvent event) {
        if (config.output.console.part) {
          print("<${event.channel.name}> ${event.user} left the channel");
        }
      });
    });

    client.register((IRC.QuitEvent event) {
      if (config.output.console.quit) {
        print("${event.user} quit");
      }
    });

    client.register((IRC.BotPartEvent event) {
      if (config.output.console.part) {
        print("Left ${event.channel.name}");
      }
    });

    client.register((IRC.MessageEvent event) {
      if (config.output.console.messages) {
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

      if (config.commands.enabled && event.message.startsWith(prefix)) {
        var without_prefix = event.message.substring(prefix.length, event.message.length);
        var parts = without_prefix.split(" ");
        if (parts.length == 0) {
          return;
        }
        var command = parts[0];
        var args = new List.from(parts)..removeAt(0);
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
