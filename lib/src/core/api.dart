part of yambot.core;

YamBot launchYamBot(String path) {
  var dir = new Directory(path).absolute;
  if (!dir.existsSync()) {
    throw new Exception("'$path' does not exist");
  }
  Directory.current = dir;
  var bot = new YamBot();
  bot.start();
  return bot;
}
