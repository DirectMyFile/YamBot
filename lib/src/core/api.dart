part of yambot.core;

YamBot launchYamBot(String base_path) {
  return new YamBot(new Directory(base_path).absolute);
}