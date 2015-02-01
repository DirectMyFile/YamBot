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
   *
   * If [prefix] is prefixed with [prefixContent].
   * If [prefixContent] is empty it becomes the display name of this plugin.
   */
  void reply(String message, {bool prefix, String prefixContent}) {
    if (prefix || (prefix == null && prefixContent != null)) {
      if (prefixContent == null) {
        prefixContent = bot.plugin.displayName;
      }

      message = "[${Color.BLUE}${prefixContent}${Color.RESET}] ${message}";
    }

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
  bool get hasOneArgument => argc == 0;
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
   * Sends [message] as a message to [channel] on [network].
   *
   * If [prefix] is prefixed with [prefixContent].
   * If [prefixContent] is empty it becomes the display name of this plugin.
   */
  void replyNotice(String message, {bool prefix, String prefixContent}) {
    if (prefix || (prefix == null && prefixContent != null)) {
      if (prefixContent == null) {
        prefixContent = bot.plugin.displayName;
      }

      message = "[${Color.BLUE}${prefixContent}${Color.RESET}] ${message}";
    }

    bot.sendNotice(network, user, message);
  }
  
  /**
   * Replies with the output from [transformer].
   */
  void transform(transformer(String input), {prefix: false, bool notice: false}) {
    var p = null;
    if (prefix == true || (prefix != null && prefix is String)) {
      p = prefix == true ? bot.plugin.displayName : prefix;
    }
    
    new Future.value(transformer(joinArgs())).then((value) {
      (notice ? replyNotice : reply)(p != null ? value : "> ${value}", prefixContent: p);
    });
  }
  
  Future<dynamic> fetchJSON(String url, {Map<String, String> headers: const {}}) {
    return bot.plugin.httpClient.get(url).then((response) {
      if (response.statusCode != 200) {
        throw new HttpException("failed to fetch JSON");
      }
      
      return JSON.decode(response.body);
    });
  }
  
  Future<String> getUsername() => whois().then((info) => info.username);
  
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
