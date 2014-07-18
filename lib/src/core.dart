part of yambot;

class YamBot {

  final config = YamlConfiguration.load();

  final Map<String, IRC.Client> _clients = {};

  IRC.Client operator [](String s) {
    return _clients[s];
  }

  void start() {
    for (var server in config['server']) {
      var botConfig = new IRC.BotConfig();

      botConfig.nickname = server['nickname'];
      botConfig.realname = server['realname'];
      botConfig.host = server['host'];
      botConfig.port = server['port'];

      IRC.Client client = new IRC.Client(botConfig);
      String name = server['name'];
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
        print("[$name] Received command '${event.command}' with args: ${event.args}");
      });

      print("[$name] Connecting");
      client.connect();
    }
  }
}
