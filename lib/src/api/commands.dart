part of polymorphic.api;

typedef SubCommandHandler(List<String> args);

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
   * Username of User
   */
  final String username;

  /**
   * Command Arguments
   */
  final List<String> args;

  String _prefix;
  bool _randomize;

  CommandEvent(
    this.bot,
    this.network,
    this.command, this.message, this.user, this.channel, this.args, this.username, {bool randomize: false}) : _randomize = randomize;

  /**
   * Sends [message] as a message to [channel] on [network].
   *
   * If [prefix] is prefixed with [prefixContent].
   * If [prefixContent] is empty it becomes the display name of this plugin.
   */
  void reply(String input, {bool prefix, String prefixContent, bool ping: false}) {
    var msgs = input.split("\n");
    for (var message in msgs) {
      var wasPrefixed = false;

      if (prefix == true || (prefix == null && prefixContent != null)) {
        if (prefixContent == null) {
          prefixContent = bot.plugin.displayName;
        }

        message = "[${Color.BLUE}${prefixContent}${Color.RESET}] ${message}";
        wasPrefixed = true;
      }

      if (!wasPrefixed && _prefix != null) {
        message = "[${Color.BLUE}${_prefix}${Color.RESET}] ${message}";
      }

      bot.sendMessage(network, channel, message, ping: ping ? user : null);
    }
  }

  /**
   * Calls [handle] if [user] has [permission].
   */
  void require(String permission, void handle()) {
    bot.checkPermission(network, channel, user, permission).run(handle);
  }

  /**
   * Handle Sub Commands
   */
  subcommands(Map<String, SubCommandHandler> handlers, {List<String> args}) {
    if (args == null) {
      args = this.args;
    }

    if (args.isEmpty) {
      usage();
      return null;
    }

    var cmd = args[0];
    var cargs = new List<String>.from(args)..removeAt(0);

    if (!handlers.keys.contains(cmd)) {
      usage();
      return null;
    }

    return handlers[cmd](cargs);
  }

  /**
   * Joins the arguments by [sep].
   */
  String joinArgs([String sep = " "]) {
    return args.join(sep);
  }

  String joinArguments([String sep = " "]) => joinArgs(sep);

  bool get hasArguments => args.isNotEmpty;
  bool get hasNoArguments => args.isEmpty;
  bool get hasOneArgument => argc == 1;
  int get argc => args.length;

  /**
   * Replies with the command's usage. If you did not specify a usage it will output '> Usage: command-name'
   */
  void usage() {
    var cmd = bot._myCommands.firstWhere((it) => it.name == command);
    var usage = "";

    if (cmd.usage != null && cmd.usage.isNotEmpty) {
      usage = cmd.usage;

      if (!usage.startsWith(command)) {
        usage = " " + usage;
      }
    }

    var needCmd = !usage.startsWith(command);
    var buff = new StringBuffer();

    if (_prefix == null) {
      buff.write("> ");
    }

    buff.write("Usage: ");

    if (needCmd) {
      buff.write(command);
      if (usage != null) {
        buff.write(" ");
      }
    }

    if (usage != null) {
      buff.write(usage);
    }

    reply(buff.toString());
  }

  void executeCommand(String command, [List<String> args = const []]) {
    bot.executeCommand(network, channel, user, command, args);
  }

  dynamic chooseAtRandom(Iterable iterator) {
    var list = iterator.toList();
    return list[new Random().nextInt(list.length)];
  }

  List<String> copyArguments() => new List<String>.from(args);
  List<String> dropArguments(int x) {
    var a = copyArguments();
    for (var i = 1; i <= x; i++) {
      a.removeAt(0);
    }
    return a;
  }

  String dropJoinArguments(int x, [String sep = " "]) {
    return dropArguments(x).join(sep);
  }

  Future<String> getChannelTopic() => bot.getChannelTopic(network, channel);
  void setChannelTopic(String topic) => bot.setChannelTopic(network, channel, topic);

  Future<BufferEntry> getLastChannelMessage() {
    return getChannelBuffer().then((entries) => entries.first);
  }

  Future<String> getLastCommand([bool userOnly = true]) {
    return bot.plugin.callMethod("getLastCommand", {
      "network": network,
      "channel": channel,
      "not": command
    }..addAll(userOnly ? { "user": user } : {}));
  }

  Future<List<BufferEntry>> getChannelBuffer() => bot.getChannelBuffer(network, channel);

  /**
   * Gets a Storage Container that is specific to this user.
   */
  StorageContainer getUserMetadata({String user, bool channelSpecific: false}) {
    if (user == null) {
      user = username != null ? username : this.user;
    }

    return bot.getUserMetadata(network, channel, user, channelSpecific: channelSpecific);
  }

  /**
   * Gets a Storage Container that is specific to this channel.
   */
  StorageContainer getChannelMetadata() {
    return bot.getChannelMetadata(network, channel);
  }

  /**
   * Sends [input] as a message to [user] on [network] as a notice.
   *
   * If [prefix] is prefixed with [prefixContent].
   * If [prefixContent] is empty it becomes the display name of this plugin.
   */
  void replyNotice(String input, {bool prefix, String prefixContent}) {
    var msgs = input.split("\n");

    for (var message in msgs) {
      var wasPrefixed = false;

      if (prefix == true || (prefix == null && prefixContent != null)) {
        if (prefixContent == null) {
          prefixContent = bot.plugin.displayName;
        }

        message = "[${Color.BLUE}${prefixContent}${Color.RESET}] ${message}";
        wasPrefixed = true;
      }

      if (!wasPrefixed && _prefix != null) {
        message = "[${Color.BLUE}${_prefix}${Color.RESET}] ${message}";
      }

      bot.sendNotice(network, user, message);
    }
  }

  /**
   * Replies with the output from [transformer].
   */
  void transform(transformer(String input), {prefix: false, bool notice: false}) {
    var p = null;

    if (prefix == true || (prefix != null && prefix is String)) {
      p = prefix == true ? bot.plugin.displayName : prefix;
    }

    if (hasNoArguments) {
      usage();
      return;
    }

    new Future.value(transformer(joinArgs())).then((value) {
      if (value == null) return;

      (notice ? replyNotice : reply)(value, prefix: p);
    });
  }

  Future<UserInfo> whois() {
    return bot.getUserInfo(network, user);
  }

  Future<Channel> getChannel() {
    return bot.getChannel(network, channel);
  }

  String operator ~() {
    return joinArguments();
  }

  operator <<(msg) {
    if (msg == null) {
      return;
    }

    if (msg is NoArgumentFunction) {
      this << msg();
    } else if (msg is Iterable) {
      if (_randomize) {
        this << chooseAtRandom(msg);
      } else {
        this << msg.join("\n");
      }
    } else if (msg is Future) {
      msg.then((value) => this << value);
    } else {
      reply(msg.toString());
    }
  }

  operator >>(Function function) {
    if (function is NoArgumentFunction) {
      if (hasArguments) {
        usage();
        return;
      }

      new Future.value(function()).then((value) {
        if (value == null) return;

        this << value;
      });
    } else if (function is OneArgumentFunction) {
      transform(function);
    } else {
      throw new ArgumentError("invalid function");
    }
  }

  operator >(Map<String, SubCommandHandler> subcommands) {
    this.subcommands(subcommands);
  }

  operator <(msg) {
    if (msg == null) {
      return;
    }

    if (msg is NoArgumentFunction) {
      var value = msg();

      if (value == null) {
        return;
      }

      if (value is Future) {
        value.then((msg) {
          if (msg == null) {
            return;
          }

          this < msg;
        });
        return;
      }
    } else if (msg is Iterable) {
      if (_randomize) {
        this << chooseAtRandom(msg);
      } else {
        this << msg.join("\n");
      }
    } else {
      replyNotice(msg.toString());
    }
  }

  bool operator %(int count) => argc == count;

  String operator [](int index) {
    return args[index];
  }
}

typedef NoArgumentFunction();
typedef OneArgumentFunction(argument);

class CommandInfo {
  final String plugin;
  final String name;
  final String usage;
  final String description;

  CommandInfo(this.plugin, this.name, this.usage, this.description);
}
