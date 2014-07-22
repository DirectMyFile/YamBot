part of bot;

/**
 * The internal configuration system.
 */
class DefaultConfig {

  /**
   * The configuration file containing bot information.
   */
  static const String file = "config.json";

  /**
   * A default workable configuration.
   */
  static final Map defaultConfig =
  {
    "server": [{
      "name": "Esper",
      "nickname": "PolymorphicBot",
      "realname": "PolymorphicBot",
      "host": "irc.esper.net",
      "port": 6667,
      "owner": "<nickserv name>",
      "password": "<nickserv password>"
    }],
    "channel": {
      "Esper": ["#directcode"]
    },
    "prefix": {
      "Esper": ["default: \$", "#directcode", "\$"]
    }
  };


  /**
   * Loads the configuration from the file system. If the configuration does
   * not exist then a default configuration will be written to the file system.
   */
  static load() {
    File f = new File(file);
    if (!f.existsSync()) {
      var encoder = new JsonEncoder.withIndent("  ");
      f.writeAsStringSync(encoder.convert(defaultConfig));
      return defaultConfig;
    }
    return JSON.decode(f.readAsStringSync());
  }
}
