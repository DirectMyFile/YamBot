part of yambot.core;

class YamBot {
  final List<Module> modules;

  Configuration _config;

  Configuration get config => _config;

  Directory base_dir;
  IRC.Client client;

  YamBot(this.base_dir) : modules = [];

  void start() {
    var config_file = new File("${base_dir.path}/config.yaml");

    if (!config_file.existsSync()) {
      config_file.createSync(recursive: true);
      config_file.writeAsStringSync('nickname: YamBot' '\n''server:' '\n''  host: irc.esper.net' '\n''  port: 6667''\n');
    }

    _load_config(config_file.readAsStringSync());
    _check_config();

    modules.addAll([new CoreModule()]);

    modules.forEach((Module module) {
      module.init(this);
    });

    var botConfig = new IRC.BotConfig();

    botConfig.nickname = config.nickname;
    botConfig.username = config.username;
    botConfig.host = config.server.host;
    botConfig.port = config.server.port;

    client = new IRC.Client(botConfig);

    /* Module Loading Hook */
    modules.forEach((Module module) {
      module.apply(client);
    });

    client.connect();
  }

  void _load_config(File config_file) {
    var config = new Configuration();
    config.loadFromYaml(config_file);
    _config = config;
  }

  void _check_config() {
    _check_config_required();
    _check_config_default();
  }

  void _check_config_required() {
    _config_check_entry_required("nickname", config.nickname != null);
    _config_check_entry_required("server", config.server != null);
    _config_check_entry_required("server.host", config.server.host != null);
    _config_check_entry_required("server.port", config.server.port != null);
  }

  /**
   * Sets Default Values (Used as Config Checking Extension)
   */
  void _check_config_default() {
    if (config.username == null)config.username = config.nickname;
    if (config.channels == null)config.channels = [];
  }

  void _config_check_entry_required(String key, bool condition) {
    if (!condition) {
      print("ERROR: the configuration entry '${key}' was not found");
      exit(1);
    }
  }
}
