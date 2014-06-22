part of yambot.config;

class Configuration {
  String nickname;
  String username;
  String realname;
  Server server;

  void loadFromYaml(String data) {
    PodoTransformer.fromMap(loadYaml(data), this);
  }
}
