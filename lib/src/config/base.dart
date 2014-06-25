part of yambot.config;

class Configuration extends PODO {
  String nickname;
  String username = "YamBot";
  String realname = "Yaml IRC Bot";
  Server server = new Server();
  List<String> channels = [];
  Commands commands = new Commands();
  Output output = new Output();

  void loadFromYaml(String data) {
    var map = loadYaml(data) as Map;
    PodoTransformer.fromMap(map, this);
  }
}
