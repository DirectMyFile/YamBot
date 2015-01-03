part of polymorphic.api;

class CommandEvent {
  final BotConnector bot;
  final String network;
  final String command;
  final String message;
  final String user;
  final String channel;
  final List<String> args;

  void reply(String message) {
    bot.sendMessage(network, channel, message);
  }

  void require(String permission, void handle()) {
    bot.checkPermission((it) => handle(), network, channel, user, permission);
  }

  void replyNotice(String message) {
    bot.sendNotice(network, user, message);
  }

  CommandEvent(this.bot, this.network, this.command, this.message, this.user, this.channel, this.args);
}

class CommandInfo {
  final String plugin;
  final String name;
  final String usage;
  final String description;
  
  CommandInfo(this.plugin, this.name, this.usage, this.description);
}