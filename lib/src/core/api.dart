part of yambot.core;

YamBot launchYamBot(String base_path) {
  var bot = new YamBot(new Directory(base_path).absolute);
  bot.start();
  return bot;
}