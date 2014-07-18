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

channel:
  Esper:
    - '#directcode'

prefix:
  Esper:
    default: \$
    '#directcode': \$
""";

  static load() {
    File f = new File(file);
    if (!f.existsSync()) {
      f.writeAsStringSync(defaultConfig);
      return loadYaml(defaultConfig);
    }
    return loadYaml(f.readAsStringSync());
  }
}
