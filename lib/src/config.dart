part of bot;

/**
 * The internal configuration system. This configuration will never
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
    nickname: PolymorphicBot
    realname: PolymorphicBot
    host: irc.esper.net
    port: 6667
    owner: <nickserv name>
    password: <nickserv password>

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
