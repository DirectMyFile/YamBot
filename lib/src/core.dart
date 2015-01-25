part of polymorphic.bot;

class BotMetrics {
  static final Counter networksMetric = new Counter("polymorphic.networkCount", "Number of Networks");
  static final Counter messagesMetric = new Counter("polymorphic.messagesCount", "Number of IRC Messages Received");
  static final Counter pluginsMetric = new Counter("polymorphic.pluginsCount", "Number of Plugins Loaded");
  
  static void init() {
    Metrics.register(networksMetric);
    Metrics.register(messagesMetric);
    Metrics.register(pluginsMetric);
  }
}

class CoreBot {
  
  /**
   * The overall configuration for the entire bot.
   */
  final config;

  final Map<String, Bot> _clients = {};

  /**
   * Initializes [CoreBot] based on the default configuration
   */
  factory CoreBot() {
    return new CoreBot.conf(DefaultConfig.load());
  }

  /**
   * Initializes [CoreBot] based on a custom configuration. The [config] must
   * conform to the same specifications as the default configuration.
   * See [DefaultConfig] for the default configuration.
   */
  CoreBot.conf(this.config) {
    for (var server in config['server']) {
      if (server['enabled'] == false) continue;
      var name = server['name'];
      var chan = config['channel'][name];
      var pref = config['prefix'][name];
      var perms = config['permissions']['server'][name];
      var groups = config['permissions']['groups'];
      var bot = new Bot(name, server, chan, pref, perms, groups);
      if (_clients.containsKey(name)) {
        throw new Exception("Server name '$name' already taken");
      }
      _clients[name] = bot;
    }
    
    BotMetrics.networksMetric.value = bots.length.toDouble();
  }

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
   * Starts all the clients based on the configuration.
   */
  void start() {
    _clients.forEach((String network, Bot bot) {
      bot.start();
    });
  }
  
  void stop() {
    if (Globals.pluginHandler != null) {
      Globals.pluginHandler.killPlugins();
    }
    
    _clients.forEach((String network, Bot bot) {
      bot.destroy();
    });
  }
  
  void restart() {
    print("[PolymorphicBot] Restarting");
    stop();
    new Future.delayed(new Duration(seconds: 5), () {
      return Globals.pluginHandler != null ? Globals.pluginHandler.init() : new Future.value();
    }).then((_) {
      start();
    });
  }
}
