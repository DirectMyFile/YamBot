part of polymorphic.api;

/**
 * A Command Event.
 */
class CommandEvent {
  /**
   * The Bot
   */
  final BotConnector bot;
  
  /**
   * Network
   */
  final String network;
  
  /**
   * Command
   */
  final String command;
  
  /**
   * Message
   */
  final String message;
  
  /**
   * User
   */
  final String user;
  
  /**
   * Channel
   */
  final String channel;
  
  /**
   * Command Arguments
   */
  final List<String> args;

  CommandEvent(this.bot, this.network, this.command, this.message, this.user, this.channel, this.args);
  
  /**
   * Sends [message] as a message to [channel] on [network].
   */
  void reply(String message) {
    bot.sendMessage(network, channel, message);
  }

  /**
   * Calls [handle] if [user] has [permission].
   */
  void require(String permission, void handle()) {
    bot.checkPermission((it) => handle(), network, channel, user, permission);
  }

  /**
   * Joins the arguments by [sep].
   */
  String joinArgs([String sep = " "]) => args.join(sep);

  bool get hasArguments => args.isNotEmpty;
  bool get hasNoArguments => args.isEmpty;
  int get argc => args.length;

  /**
   * Replies with the command's usage. If you did not specify a usage it will output '> Usage: command-name'
   */
  void usage() {
    var cmd = bot._myCommands.firstWhere((it) => it.name == command);
    if (cmd.usage != null && cmd.usage.isNotEmpty) {
      var needCmd = !cmd.usage.startsWith(command);
      reply("> Usage: ${needCmd ? '${command} ' : ''}${cmd.usage}");
    }
  }

  /**
   * Sends [message] as a notice to [channel] on [network].
   */
  void replyNotice(String message) {
    bot.sendNotice(network, user, message);
  }
  
  Future<UserInfo> whois() {
    return bot.getUserInfo(network, user);
  }
  
  Future<Channel> getChannel() {
    return bot.getChannel(network, channel);
  }
}

class CommandInfo {
  final String plugin;
  final String name;
  final String usage;
  final String description;

  CommandInfo(this.plugin, this.name, this.usage, this.description);
}
