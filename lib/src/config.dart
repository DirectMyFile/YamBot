part of yambot;

/**
 * The internal configuration system for YamBot. This configuration will never
 * change at runtime and remains static.
 */
class YamlConfiguration {

  /**
   * The configuration file containing bot information.
   */
  static const String file = "config.yaml";

  /**
   * A default configuration that is workable.
   */
  static const String defaultConfig =
"""
server:
  - name: Esper
    nickname: YamBot
    realname: YamBot
    host: irc.esper.net
    port: 6667
    owner: <nickserv name>

channel:
  Esper:
    - '#directcode'

prefix:
  Esper:
    default: \$
    '#directcode': \$
""";

  /**
   * Loads the configuration from the file system. If the configuration does
   * not exist then a default configuration will be written to the file system.
   */
  static load() {
    File f = new File(file);
    if (!f.existsSync()) {
      f.writeAsStringSync(defaultConfig);
      return loadYaml(defaultConfig);
    }
    return loadYaml(f.readAsStringSync());
  }
}
