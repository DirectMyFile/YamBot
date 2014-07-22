part of bot;

class CoreBot {

  /**
   * The overall configuration for the entire bot.
   */
  final config;

  final Map<String, Bot> _clients = {};

  /**
   * Initializes [CoreBot] based on the default configuration
   */
  CoreBot() : config = YamlConfiguration.load();

  /**
   * Initializes [CoreBot] based on a custom configuration. The [config] must
   * conform to the same specifications as the default configuration.
   * See [YamlConfiguration] for the default configuration.
   */
  CoreBot.conf(this.config);

  /**
   * Gets a bot by its name.
   */
  Bot operator [](String s) {
    return _clients[s];
  }

  /**
   * Get all the bot names.
   */
  List<String> get bots => _clients.keys.toList(growable: false);

  /**
   * Loads in all the [Bot]s, but doesn't connect them. See [start] for
   * connecting the [Bot]s.
   */
  void init() {
    for (var server in config['server']) {
      var name = server['name'];
      var chan = config['channel'][name];
      var pref = config['prefix'][name];
      Bot b = new Bot(name, server, chan, pref);
      if (_clients.containsKey(name)) {
        throw new Exception("Server name '$name' already taken");
      }
      _clients[name] = b;
    }
  }

  /**
   * Starts all the clients based on the configuration.
   */
  void start() {
    _clients.forEach((String net, Bot bot) {
      bot.start();
    });
  }
}
