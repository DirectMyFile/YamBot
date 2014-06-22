part of yambot.core;

class YamBot {
  Directory base_dir;

  YamBot(this.base_dir);

  void start() {
    var config_file = new File("${base_dir}/config.yaml");
  }

  void load_config() {
  }
}
