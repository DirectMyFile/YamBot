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
   * Sends [message] as a notice to [channel] on [network].
   */
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
