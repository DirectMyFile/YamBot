part of polymorphic.bot;

const String DEFAULT_CONFIG = """
networks:
- name: EsperNet
  nickname: PolymorphicBot
  realname: PolymorphicBot
  host: irc.esper.net
  port: 6667
  owner: NickServ Name Here
  password: NickServ Password Here
  broadcast: true
  channels:
  - '#directcode'
  prefix: .
http:
  port: 8050
  url: http://127.0.0.1:8050
""";

/**
 * The internal configuration system.
 */
class DefaultConfig {
  /**
   * Loads the configuration from the file system. If the configuration does
   * not exist then a default configuration will be written to the file system.
   */
  static load() {
    var file = new File("config.yaml");
    var jfile = new File("config.json");
    
    if (!file.existsSync()) {
      if (jfile.existsSync()) { // Perform migration.
        print("[Configuration] Migrating old JSON configuration to YAML configuration.");
        var conf = JSON.decode(jfile.readAsStringSync());
        file.writeAsStringSync(encodeYAML(conf));
        jfile.deleteSync();
      } else {
        file.writeAsStringSync(DEFAULT_CONFIG);
      }
    }
    
    return crawlYAML(yaml.loadYaml(file.readAsStringSync()));
  }
}
