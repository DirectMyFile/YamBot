part of polymorphic.bot;

class Bot {

  /**
   * The network name.
   */
  final String server;

  /**
   * Holds basic information to start a bot.
   */
  final serverConfig;

  /**
   * Holds the channel information the bot should auto join.
   */
  final channelConfig;

  /**
   * Holds the prefix information for the network or individual channels.
   */
  final prefixConfig;

  /**
   * The client which manages the IRC connections and data.
   */
  IRC.Client get client => _client;
  IRC.Client _client;

  Bot(this.server, this.serverConfig, this.channelConfig, this.prefixConfig) {
    var botConfig = new IRC.BotConfig();
    botConfig.nickname = serverConfig['nickname'];
    botConfig.realname = serverConfig['realname'];
    botConfig.host = serverConfig['host'];
    botConfig.port = serverConfig['port'];
    _client = new IRC.Client(botConfig);

    _registerRawHandler();
    _registerReadyHandler();
    _registerMessageHandler();
    _registerCommandHandler();
  }

  void start() {
    print("[$server] Connecting");
    client.connect();
  }

  void _registerRawHandler() {
    void _rawHandler(IRC.LineReceiveEvent event) {
      print("[$server] ${event.line}");
    }
    client.register(_rawHandler);
    client.register((IRC.ReadyEvent event) => client.unregister(_rawHandler));
  }

  void _registerReadyHandler() {
    client.register((IRC.ReadyEvent event) {
      client.identify(username: serverConfig['owner'],
                      password: serverConfig['password']);
      print("[$server] Bot is Ready");
      for (var chan in channelConfig) {
        print("[$server] Joining $chan");
        event.join(chan);
      }
    });
  }

  void _registerMessageHandler() {
    client.register((IRC.MessageEvent event) {
      var from = event.from;
      var msg = event.message;
      if (event.isPrivate) {
        print("[$server] <$from> $msg");
      } else {
        print("[$server] <${event.channel.name}><$from> $msg");
      }

      String prefix;
      if (!event.isPrivate)
        prefix = prefixConfig[event.channel.name];
      if (prefix == null)
        prefix = prefixConfig['default'];
      if (prefix == null)
        throw new Exception("[$server] No prefix set");
      if (event.message.startsWith(prefix)) {
        List<String> args = event.message.split(' ');
        String command = args[0].substring(1);
        args.removeAt(0);
        client.post(new IRC.CommandEvent(event, command, args));
      }
    });
  }

  void _registerCommandHandler() {
    Auth auth = new Auth(server, client);
    client.register((IRC.CommandEvent event) {
      if (event.command == "auth") {
        if (event.args.length == 0) {
          auth.registeredAs(event.from).then((List<String> s) {
            if (s[0] == null) {
              event.reply("> ${s[1]}");
            } else {
              event.reply("> You are authenticated as ${s[0]}");
            }
          });
        } else if (event.args.length == 1) {
          if (!event.isPrivate && event.args[0] == "force") {
            auth.registeredAs(event.from).then((List<String> s) {
              if (s[0] == null) {
                event.reply("> Forcing an authentication lookup");
                auth.authenticate(event.from);
              } else {
                event.reply("> ${Auth.LOGGED}");
              }
            });
          }
        }
      }
    });
  }
}
