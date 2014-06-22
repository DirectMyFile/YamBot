part of yambot.config;

class Configuration {
  String nickname;
  String username;
  String realname;

  void loadFromYaml(String data) {
    PodoTransformer.fromMap(loadYaml(data), this);
  }
}
