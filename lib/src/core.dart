part of yambot;

class YamBot {

  /**
   * The overall configuration for the entire bot.
   */
  final config;

  final Map<String, Bot> _clients = {};

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
   * Gets a bot by its name.
   */
  Bot operator [](String s) {
    return _clients[s];
  }

  /**
   * Starts all the clients based on the configuration.
   */
  void start() {
    for (var server in config['server']) {
      var name = server['name'];
      var chan = config['channel'][name];
      var pref = config['prefix'][name];
      Bot b = new Bot(name, server, chan, pref)..start();
      if (_clients.containsKey(name))
        throw new Exception("Server name '$name' already taken");
      _clients[name] = b;
    }
  }
}
