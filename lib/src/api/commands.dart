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
    bot.message(network, channel, message);
  }

  void require(String permission, void handle()) {
    bot.permission((it) => handle(), network, channel, user, permission);
  }

  void replyNotice(String message) {
    bot.notice(network, user, message);
  }

  CommandEvent(this.bot, this.network, this.command, this.message, this.user, this.channel, this.args);
}