part of yambot;

class YamBot {

  final config;

  final Map<String, IRC.Client> _clients = {};

  /**
   * Initializes [YamBot] based on the default configuration
   */
  YamBot() : config = YamlConfiguration.load();

  /**
   * Initializes [YamBot] based on a custom configuration. The [config] must
   * conform to the same specifications as the default configuration.
   * See [YamlConfiguration] for the default configuration.
   */
  YamBot.conf(this.config);

  /**
   * Gets a client by its name.
   */
  IRC.Client operator [](String s) {
    return _clients[s];
  }

  /**
   * Starts all the clients based on the configuration.
   */
  void start() {
    for (var server in config['server']) {
      var botConfig = new IRC.BotConfig();

      botConfig.nickname = server['nickname'];
      botConfig.realname = server['realname'];
      botConfig.host = server['host'];
      botConfig.port = server['port'];

      IRC.Client client = new IRC.Client(botConfig);
      String name = server['name'];
      Auth auth = new Auth(name, client);
      _clients[name] = client;

      void _rawHandler(IRC.LineReceiveEvent event) {
        print("[$name] ${event.line}");
      }

      client.register(_rawHandler);

      client.register((IRC.ReadyEvent event) {
        print("[$name] Connection complete");
        client.unregister(_rawHandler);
        for (var chan in config['channel'][name]) {
          print("[$name] Joining $chan");
          event.join(chan);
        }
      });

      client.register((IRC.MessageEvent event) {
        if (event.isPrivate) {
          print("[$name] <${event.from}> ${event.message}");
        } else {
          print("[$name] <${event.channel.name}><${event.from}> ${event.message}");
        }

        String prefix;
        if (!event.isPrivate)
          prefix = config['prefix'][name][event.channel.name];
        if (prefix == null)
          prefix = config['prefix'][name]['default'];
        if (prefix == null)
          throw new Exception("[$name] No prefix set");
        if (event.message.startsWith(prefix)) {
          List<String> args = event.message.split(' ');
          String command = args[0].substring(1);
          args.removeAt(0);
          client.post(new IRC.CommandEvent(event, command, args));
        }
      });

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
                  event.reply("> You are already logged into NickServ");
                }
              });
            }
          }
        }
      });

      print("[$name] Connecting");
      client.connect();
    }
  }
}
