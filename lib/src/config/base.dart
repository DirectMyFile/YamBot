part of yambot.config;

class Configuration extends PODO {
  String nickname;
  String username;
  String realname;
  Server server;
  List<String> channels;
  Commands commands;

  void loadFromYaml(String data) {
    PodoTransformer.fromMap(loadYaml(data), this);
  }
}
