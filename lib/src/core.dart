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

      var client = new IRC.Client(botConfig);
      _clients[server['name']] = client;

      void _rawHandler(IRC.LineReceiveEvent event) {
        print("[${server['name']}] ${event.line}");
      }

      client.register(_rawHandler);

      client.register((IRC.ReadyEvent event) {
        print("[${server['name']}] Connection complete");
        client.unregister(_rawHandler);
        for (var chan in config['channel'][server['name']]) {
          print("[${server['name']}] Joining $chan");
          event.join(chan);
        }
      });

      print("[${server['name']}] Connecting");
      client.connect();
    }
  }
}
