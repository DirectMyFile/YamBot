part of polymorphic.api;

/**
 * Action that runs when the plugin is ready.
 */
typedef void ReadyAction();

typedef void _SingleParameterFunction(a);
typedef void _TwoParameterFunction(a, b);

/**
 * PolymorphicBot IRC-specific interface.
 */
class BotConnector {
  /**
   * Plugin Instance.
   */
  final Plugin plugin;

  BotConnector(this.plugin);

  /**
   * Gets the bot configuration.
   */
  Future<Map<String, dynamic>> getConfig() => plugin.callMethod("getConfig");

  /**
   * Gets the bot configuration.
   *
   * NOTICE: Prefer [getConfig].
   */
  Future<Map<String, dynamic>> get config => getConfig();

  /**
   * Checks a permission on a user.
   *
   * [target] is where to send the message if the node is not matched.
   * [callback] is not called if the [user] has no permissions.
   */
  void checkPermission(void callback(Map data), String network, String target, String user, String node, [bool notify]) {
    Map params = {
      "node": node,
      "network": network,
      "user": user,
      "target": target,
      "notify": notify
    };

    plugin.callMethod("checkPermission", params).then((has) {
      if (has) {
        callback(has);
      }
    });
  }

  /**
   * Calls [handler] when a bot is detected.
   *
   * If [network] is provided then the handler will be called only if the event came from the given network.
   */
  void onBotDetected(BotDetectionHandler handler, {String network}) {
    var sub = plugin.on("bot-detected").where((data) {
      if (network != null && network != data["network"]) return false;
      return true;
    }).listen((data) {
      var event = new BotDetectionEvent(this, data["network"], data["user"]);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Changes Modes
   *
   * [mode] is the mode to change.
   * [user] is the user to change it on.
   * [channel] is the channel to change it on.
   */
  void mode(String network, String mode, {String user, String channel}) {
    plugin.callMethod("mode", {
      "network": network,
      "mode": mode,
      "user": user,
      "channel": channel
    });
  }

  /**
   * Ops [user] in [channel] on [network].
   */
  void op(String network, String channel, String user) {
    mode(network, "+o", channel: channel, user: user);
  }

  /**
   * Deops [user] in [channel] on [network].
   */
  void deop(String network, String channel, String user) {
    mode(network, "-o", channel: channel, user: user);
  }

  /**
   * Voices [user] in [channel] on [network].
   */
  void voice(String network, String channel, String user) {
    mode(network, "+v", channel: channel, user: user);
  }

  /**
   * Devoices [user] in [channel] on [network].
   */
  void devoice(String network, String channel, String user) {
    mode(network, "-v", channel: channel, user: user);
  }

  /**
   * HalfOps [user] in [channel] on [network].
   */
  void halfOp(String network, String channel, String user) {
    mode(network, "+h", channel: channel, user: user);
  }

  /**
   * DeHalfOps [user] in [channel] on [network].
   */
  void dehalfOp(String network, String channel, String user) {
    mode(network, "-h", channel: channel, user: user);
  }

  /**
   * Owners [user] in [channel] on [network].
   */
  void owner(String network, String channel, String user) {
    mode(network, "+q", channel: channel, user: user);
  }

  /**
   * Deowners [user] in [channel] on [network].
   */
  void deowner(String network, String channel, String user) {
    mode(network, "-q", channel: channel, user: user);
  }

  /**
   * Quiets [user] in [channel] on [network].
   */
  void quiet(String network, String channel, String user) {
    mode(network, "+q", channel: channel, user: user);
  }

  /**
   * Unquiets [user] in [channel] on [network].
   */
  void unquiet(String network, String channel, String user) {
    mode(network, "-q", channel: channel, user: user);
  }

  /**
   * Set the topic for [channel] on [network] to [topic].
   */
  void setTopic(String network, String channel, String topic) {
    getChannel(network, channel).then((channel) => channel.topic = topic);
  }

  StorageContainer getUserMetadata(String network, String channel, String user, {bool channelSpecific: false}) {
    return plugin.getStorage("metadata").getSubStorage(channelSpecific ? "${network}:${channel}:${user}" : "${network}:${user}");
  }

  StorageContainer getChannelMetadata(String network, String channel) {
    return plugin.getStorage("metadata").getSubStorage("${network}:${channel}");
  }

  /**
   * Kicks [user] in [channel] on [network].
   */
  void kick(String network, String channel, String user, {String reason}) {
    plugin.callMethod("kick", {
      "network": network,
      "channel": channel,
      "user": user,
      "reason": reason
    });
  }

  /**
   * Bans [user] in [channel] on [network].
   */
  void ban(String network, String channel, String user) {
    mode(network, "+b", channel: channel, user: user);
  }

  /**
   * Kickbans [user] in [channel] on [network].
   */
  void kickBan(String network, String channel, String user, {String reason}) {
    ban(network, channel, user);
    kick(network, channel, user, reason: reason);
  }

  /**
   * Unbans [user] in [channel] on [network].
   */
  void unban(String network, String channel, String user) {
    mode(network, "-b", channel: channel, user: user);
  }

  void restart() {
    plugin.callMethod("restart", {});
  }

  /**
   * Gets User Information for the given [user] on [network].
   */
  Future<UserInfo> getUserInfo(String network, String user) {
    return plugin.callMethod("whois", {
      "network": network,
      "user": user
    }).then((data) {
      return new UserInfo(this, network, data["nickname"], data["username"], data["realname"], data["away"], data["awayMessage"], data["isServerOperator"], data["hostname"], data["idle"], data["idleTime"], data["memberIn"], data["operatorIn"], data["voiceIn"], data["halfOpIn"], data["ownerIn"], data["channels"]);
    });
  }
  
  Future<List<Channel>> getChannels(String network) {
    var group = new FutureGroup();
    
    return listChannels(network).then((names) {
      for (var name in names) {
        group.add(getChannel(network, name));
      }
      
      return group.future;
    });
  }
  
  Future<List<String>> listChannels(String network) {
    return plugin.callMethod("listChannels", {
      "network": network
    });
  }

  /**
   * Gets Channel Information for the given channel [name] on [network].
   */
  Future<Channel> getChannel(String network, String name) {
    return plugin.callMethod("getChannel", {
      "network": network,
      "channel": name
    }).then((data) {
      return new Channel(this, network, name, data["topic"], data["members"], data["ops"], data["voices"], data["halfops"], data["owners"]);
    });
  }
  
  Future<bool> isInChannel(String network, String name) {
    return plugin.callMethod("isInChannel", {
      "network": network,
      "channel": name
    });
  }

  /**
   * Calls [handler] when the bot is ready on a network.
   *
   * If [network] is provided then the handler is only called if the network is the given network.
   */
  void onReady(ReadyHandler handler, {String network}) {
    var sub = plugin.on("ready").where((data) {
      if (network != null) {
        return data["network"] == network;
      }
      return true;
    }).map((it) {
      var network = it["network"];

      return new ReadyEvent(this, network);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when an action is received.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [target] is provided the handler will be called only if the target was the given target.
   * If [message] is provided the handler will be called only if the message was the given message.
   * If [user] is provided the handler will be called only if the user was the given user.
   */
  void onAction(ActionHandler handler, {String network, String user, String target, String message}) {
    onCTCP((event) {
      if (event.message.startsWith("ACTION ")) {
        var msg = event.message.substring("ACTION ".length);

        if (msg != null && msg != message) {
          return;
        }

        handler(new ActionEvent(this, event.network, event.target, event.user, event.message.substring("ACTION ".length)));
      }
    }, network: network, user: user, target: target);
  }

  /**
   * Calls [handler] when a notice is received.
   *
   * If [pattern] is provided then the handler is called only if the notice matches the given pattern.
   */
  void onNotice(NoticeHandler handler, {Pattern pattern}) {
    var sub = plugin.on("notice").where((data) {
      if (pattern != null) {
        return data['message'].allMatches(pattern).isNotEmpty;
      }
      return true;
    }).map((it) {
      var network = it["network"];
      var target = it["target"];
      var from = it["from"];
      var private = it["private"];
      var message = it["message"];

      return new NoticeEvent(this, network, target, from, private, message);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Sends [message] to [target] on [network] as a message.
   */
  void sendMessage(String network, String target, String message, {String ping}) {
    plugin.callMethod("sendMessage", {
      "network": network,
      "message": message,
      "target": target,
      "ping": ping
    });
  }

  /**
   * Sends [message] to [target] on [network] as an action.
   */
  void sendAction(String network, String target, String message) {
    plugin.callMethod("sendAction", {
      "network": network,
      "message": message,
      "target": target
    });
  }

  /**
   * Joins [channel] on [network].
   */
  void joinChannel(String network, String channel) {
    plugin.callMethod("joinChannel", {
      "network": network,
      "channel": channel
    });
  }

  /**
   * Leaves [channel] on [network].
   */
  void partChannel(String network, String channel) {
    plugin.callMethod("partChannel", {
      "network": network,
      "channel": channel
    });
  }

  /**
   * Sends the raw IRC [line] to [network].
   */
  void sendRawLine(String network, String line) {
    plugin.callMethod("sendRawLine", {
      "network": network,
      "line": line
    });
  }

  /**
   * Gets the plugins that are loaded.
   */
  Future<List<String>> getPlugins() {
    return plugin.getPlugins();
  }

  /**
   * Gets the networks this bot is configured for.
   */
  Future<List<String>> getNetworks() {
    return plugin.callMethod("getNetworks");
  }

  /**
   * Sends [message] to [target] on [network] as a notice.
   */
  void sendNotice(String network, String target, String message) {
    plugin.callMethod("sendNotice", {
      "network": network,
      "message": message,
      "target": target
    });
  }

  /**
   * Calls [handler] when a message is received.
   *
   * If [pattern] is provided then the handler is called only if the message matches the given pattern.
   */
  void onMessage(MessageHandler handler, {pattern, bool ping, bool regex: false, bool caseSensitive: false}) {
    if (regex && pattern is! RegExp) {
      pattern = new RegExp(pattern.toString(), caseSensitive: caseSensitive);
    }

    if (pattern != null && pattern is! RegExp) {
      throw new Exception("We only accept Regular Expressions for the time being.");
    }

    var r = pattern as RegExp;

    var match;
    var sub = plugin.on("message").where((data) {
      var matched = true;

      if (ping != null && ping) {
        matched = matched && data['ping'];
      }

      if (pattern != null) {
        var m = data['msgnoping'];

        if (matched && r.hasMatch(data['message'])) {
          matched = true;
          match = r.firstMatch(data['message']);
        } else {
          matched = false;
        }
      }

      return matched;
    }).map((it) {
      var network = it["network"];
      var target = it["target"];
      var from = it["from"];
      var private = it["private"];
      var message = it["message"];
      var isPing = it["ping"];

      return new MessageEvent(this, network, target, from, private, isPing, message, match: match);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Checks if the given [user] on [network] is a bot.
   */
  Future<bool> isUserABot(String network, String user) {
    return plugin.callMethod("isUserABot", {
      "network": network,
      "user": user
    });
  }

  /**
   * Gets the prefix for the given [channel] on [network].
   */
  Future<String> getPrefix(String network, String channel) {
    return plugin.callMethod("getPrefix", {
      "network": network,
      "channel": channel
    });
  }

  /**
   * Calls [handler] when a user joins a channel.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [channel] is provided the handler will be called only if the channel was the given channel.
   * If [user] is provided the handler will be called only if the user is the given user.
   */
  void onJoin(JoinHandler handler, {String channel, String user, String network}) {
    var sub = plugin.on("join").where((data) {
      bool matches = true;
      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      if (user != null && user != data["user"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String user = data['user'];
      String channel = data['channel'];

      var event = new JoinEvent(this, network, channel, user);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when a user leaves a channel.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [channel] is provided the handler will be called only if the channel was the given channel.
   * If [user] is provided the handler will be called only if the user is the given user.
   */
  void onPart(PartHandler handler, {String channel, String user, String network}) {
    var sub = plugin.on("part").where((data) {
      bool matches = true;

      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      if (user != null && user != data["user"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String user = data['user'];
      String channel = data['channel'];

      var event = new PartEvent(this, network, channel, user);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when a user quits the server.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [user] is provided the handler will be called only if the user is the given user.
   */
  void onQuit(QuitHandler handler, {String user, String network}) {
    var sub = plugin.on("quit").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) {
        matches = false;
      }

      if (user != null && user != data["user"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String user = data['user'];

      var event = new QuitEvent(this, network, user);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when a user quits a channel.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [channel] is provided the handler will be called only if the channel was the given channel.
   * If [user] is provided the handler will be called only if the user is the given user.
   */
  void onQuitPart(QuitPartHandler handler, {String channel, String user, String network}) {
    var sub = plugin.on("quit-part").where((data) {
      bool matches = true;
      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      if (user != null && user != data["user"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String user = data['user'];
      String channel = data['channel'];

      var event = new QuitPartEvent(this, network, channel, user);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Reloads Plugins.
   */
  void reloadPlugins() {
    plugin.callMethod("reloadPlugins");
  }

  /**
   * Stops the Bot.
   */
  void stop() {
    plugin.callMethod("stop");
  }

  /**
   * Clears the Bot Detection Memory.
   */
  void clearBotMemory(String network) {
    plugin.callMethod("clearBotMemory", {
      "network": network
    });
  }

  /**
   * Quits the given [network] with an optional [reason].
   */
  void quit(String network, [String reason]) {
    plugin.callMethod("quit", {
      "network": network,
      "reason": reason
    });
  }

  /**
   * Calls [handler] when the bot joins a channel.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [channel] is provided the handler will be called only if the channel was the given channel.
   */
  void onBotJoin(BotJoinHandler handler, {String network, String channel}) {
    var sub = plugin.on("bot-join").where((data) {
      bool matches = true;

      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String channel = data['channel'];

      var event = new BotJoinEvent(this, network, channel);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when a CTCP message is received.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [target] is provided the handler will be called only if the target was the given target.
   * If [message] is provided the handler will be called only if the message was the given message.
   * If [user] is provided the handler will be called only if the user was the given user.
   */
  void onCTCP(CTCPHandler handler, {String network, String target, String message, String user}) {
    var sub = plugin.on("ctcp").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (target != null && target != data["target"]) matches = false;
      if (message != null && message != data["message"]) matches = false;
      if (user != null && user != data["user"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new CTCPEvent(this, data["network"], data["target"], data["user"], data["message"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }
  
  void executeCommand(String network, String channel, String user, String command, [List<String> args = const []]) {
    plugin.callMethod("executeCommand", {
      "network": network,
      "channel": channel,
      "user": user,
      "command": command,
      "args": args
    });
  }

  /**
   * Calls [handler] when the bot is invited to a channel.
   *
   * If [network] is provided the handler will be called only if the event is from the given network.
   * If [user] is provided the handler will be called only if the event is from the given user.
   * If [channel] is provided the handler will be called only if the event is from the given channel.
   */
  void onInvite(InviteHandler handler, {String network, String user, String channel}) {
    var sub = plugin.on("invite").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (user != null && user != data["user"]) matches = false;
      if (channel != null && channel != data["channel"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new InviteEvent(this, data["network"], data["user"], data["channel"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when the bot connects to a network.
   *
   * If [network] is provided the handler will be called only if the event is from the given network.
   */
  void onConnect(ConnectHandler handler, {String network}) {
    var sub = plugin.on("connect").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new ConnectEvent(this, data["network"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when the bot disconnects from a network.
   *
   * If [network] is provided the handler will be called only if the event is from the given network.
   */
  void onDisconnect(DisconnectHandler handler, {String network}) {
    var sub = plugin.on("disconnect").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new DisconnectEvent(this, data["network"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when a channel's topic is changed or received.
   *
   * If [network] is provided the handler will be called only if the event is from the given network.
   * If [channel] is provided the handler will be called only if the event is from the given channel.
   */
  void onChannelTopic(TopicHandler handler, {String network, String channel}) {
    var sub = plugin.on("topic").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (channel != null && channel != data["channel"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new TopicEvent(this, data["network"], data["user"], data["channel"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when a user's mode is changed.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [channel] is provided the handler will be called only if the channel was the given channel.
   * If [user] is provided the handler will be called only if the user was the given user.
   * If [mode] is provided the handler will be called only if the mode is the given mode.
   */
  void onMode(ModeHandler handler, {String network, String channel, String user, String mode}) {
    var sub = plugin.on("mode").where((data) {
      bool matches = true;

      if (network != null && network != data["network"]) matches = false;
      if (user != null && user != data["user"]) matches = false;
      if (channel != null && channel != data["channel"]) matches = false;
      if (mode != null && mode != data["mode"]) matches = false;

      return matches;
    }).listen((data) {
      var event = new ModeEvent(this, data["network"], data["channel"], data["user"], data["mode"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Calls [handler] when the bot leaves a channel.
   *
   * If [network] is provided the handler will be called only if the channel was on the given network.
   * If [channel] is provided the handler will be called only if the channel was the given channel.
   */
  void onBotPart(BotPartHandler handler, {String network, String channel}) {
    var sub = plugin.on("bot-part").where((data) {
      bool matches = true;

      if (channel != null && channel != data["channel"]) {
        matches = false;
      }

      if (network != null && network != data["network"]) {
        matches = false;
      }

      return matches;
    }).listen((data) {
      String network = data['network'];
      String channel = data['channel'];

      var event = new BotPartEvent(this, network, channel);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  /**
   * Gets Command Info.
   *
   * If [pluginName] is provided it gets it from only that plugin, otherwise it gets all commands.
   */
  Future<List<CommandInfo>> getCommands([String pluginName]) {
    return plugin.callMethod("getCommandInfo", pluginName != null ? {
      "plugin": pluginName
    } : {}).then((response) {
      if (response == null) {
        return null;
      }

      var infos = [];

      for (var key in response.keys) {
        var i = response[key];
        infos.add(new CommandInfo(i["plugin"], key, i["usage"], i["description"]));
      }

      return infos;
    });
  }

  List<CommandInfo> _myCommands = [];

  /**
   * Checks if a given command [name] exists.
   */
  Future<bool> doesCommandExist(String name) {
    return plugin.callMethod("doesCommandExist", name);
  }

  /**
   * Gets command information for the given command by [name].
   */
  Future<CommandInfo> getCommand(String name) {
    return plugin.callMethod("getCommandInfo", {
      "command": name
    }).then((response) {
      if (response == null) {
        return null;
      }

      var i = response;
      return new CommandInfo(i["plugin"], name, i["usage"], i["description"]);
    });
  }

  /**
   * Registers a command with the name given by [name] to the given [handler].
   *
   * If [usage] or [description] is provided it is provided to other plugins.
   * If [permission] is given the command will require that permission to use it.
   */
  void command(String name, CommandHandler handler, {String usage: "", String description: "Not Provided", String permission, bool allowVariables: false}) {
    var info = new CommandInfo(plugin.name, name, usage, description);
    _myCommands.add(info);

    onCommand((CommandEvent event) {
      if (event.command != name) {
        return;
      }

      if (permission != null) {
        event.require(permission, () {
          handler(event);
        });
      } else {
        handler(event);
      }
    }, allowVariables: allowVariables);
  }
  
  void emitBotEvent(String event, Map<String, dynamic> data) {
    var map = {
      "event": event
    }..addAll(data);
    
    plugin.callMethod("emit", map);
  }
  
  Future<String> getMOTD(String network) {
    return plugin.callMethod("getMOTD", {
      "network": network
    });
  }
  
  Future<Map<String, dynamic>> getSupported(String network) {
    return plugin.callMethod("getSupported", {
      "network": network
    });
  }
  
  Future<bool> isConnected(String network) {
    return plugin.callMethod("isConnected", {
      "network": network
    });
  }
  
  Future<String> getNetworkName(String network) {
    return plugin.callMethod("getNetworkName", {
      "network": network
    });
  }

  Future<List<BufferEntry>> getChannelBuffer(String network, String channel) {
    return plugin.callMethod("getChannelBuffer", {
      "network": network,
      "channel": channel
    }).then((result) {
      return result.map((e) {
        return new BufferEntry.fromData(e);
      }).toList();
    });
  }

  void appendChannelBuffer(BufferEntry entry) {
    plugin.callMethod("appendChannelBuffer", entry.toData());
  }

  void onCommand(CommandHandler handler, {bool allowVariables: false}) {
    var sub = plugin.on("command").listen((data) {
      String command = data['command'];
      List<String> args = data['args'];

      String user = data['from'];
      String channel = data['target'];
      String network = data['network'];
      String message = data['message'];

      void emit() {
        var event = new CommandEvent(this, network, command, message, user, channel, args);
        handler(event);
      }

      if (allowVariables == true) {
        var variables = <String, String>{
          "channel": channel,
          "network": network,
          "command": command,
        };

        getBotNickname(network).then((nickname) {
          variables["bot.nickname"] = nickname;
          return getChannelBuffer(network, channel);
        }).then((List<BufferEntry> buffer) {
          if (buffer == null || buffer.isEmpty) {
            return null;
          }

          var last = buffer.first;

          variables["last.message"] = last.message;
          variables["last.user"] = last.user;
        }).then((_) {
          var argz = args.join(" ");
          for (var variable in variables.keys) {
            argz = argz.replaceAll("%${variable}%", variables[variable]);
          }

          args = argz.split(" ");

          emit();
        });
      } else {
        emit();
      }
    });

    plugin.registerSubscription(sub);
  }

  Future<String> getBotNickname(String network) {
    return plugin.callMethod("getBotNickname", network);
  }

  /**
   * Sends [msg] to [target] on [network] as a Client to Client Protocol Message.
   */
  void sendCTCP(String network, String target, String msg) {
    plugin.callMethod("sendCTCP", {
      "network": network,
      "target": target,
      "message": msg
    });
  }
}

typedef void PluginEventHandler(String plugin, Map<String, dynamic> data);

Plugin polymorphic(List<String> args, SendPort port, {bool load: true}) {
  var plugin = new Plugin(args[0], args[1], port);

  if (load) {
    plugin.load();
  }

  return plugin;
}

class Plugin {
  /**
   * Plugin Name
   */
  final String name;

  /**
   * Plugin Display Name
   */
  final String displayName;
  final SendPort _port;

  /**
   * HTTP Client to use for your plugin.
   */
  http.Client httpClient;

  Plugin(this.name, this.displayName, this._port) {
    _createdPlugin = true;
  }

  Receiver _conn;
  BotConnector _bot;
  List<StreamSubscription> _subs = [];
  StreamSubscription _eventSub;
  List<ShutdownAction> _shutdown = [];
  Map<String, StreamController> _controllers = {};
  List<Storage> _storages = [];
  Map<String, RemoteCallHandler> _methods = {};
  List<PluginEventHandler> _pluginEventHandlers = [];

  bool _isShutdown = false;

  /**
   * Pauses Plugin.
   */
  void disable() => _eventSub.pause();

  /**
   * Resumes Plugin.
   */
  void enable() => _eventSub.resume();

  /**
   * Gets an event stream for the event with the given [name].
   */
  Stream<Map<String, dynamic>> on(String name) {
    _init();

    if (!_controllers.containsKey(name)) {
      _controllers[name] = new StreamController.broadcast();
    }

    return _controllers[name].stream;
  }

  /**
   * Initializes the Plugin.
   */
  void load() {
    _init();
  }

  List<ReadyAction> _readyActions = [];

  /**
   * Calls [action] when the plugin is ready.
   */
  void onPluginReady(ReadyAction action) {
    _init();
    _readyActions.add(action);
  }

  /**
   * Calls [action] when the plugin is shutting down.
   */
  void onShutdown(ShutdownAction action) {
    _init();

    _shutdown.add(action);
  }

  /**
   * Registers a subscription specified by [sub] to be canceled when the plugin is shutting down.
   */
  void registerSubscription(StreamSubscription sub) {
    _init();

    _subs.add(sub);
  }

  /**
   * Pipes the event given with [data] into event handlers as if it came from the bot.
   */
  void _handleEvent(Map<String, dynamic> data) {
    _init();

    if (_isShutdown) {
      return;
    }

    String name = data['event'];

    if (_controllers.containsKey(name)) _controllers[name].add(data);
  }

  /**
   * Gets a Plugin Interface for the given [plugin].
   */
  PluginInterface getPluginInterface(String plugin) {
    if (!_interfaces.containsKey(plugin)) {
      _interfaces[plugin] = new PluginInterface(this, plugin);
    }
    return _interfaces[plugin];
  }

  Map<String, PluginInterface> _interfaces = {};

  /**
   * Plugin HTTP Server.
   *
   * This will be null until [startHttpServer] is called.
   */
  HttpServer httpServer;

  List<PluginExceptionHandler> _exceptionHandlers = [];

  /**
   * Handles Exceptions.
   */
  void onException(PluginExceptionHandler handler) {
    _exceptionHandlers.add(handler);
  }

  /**
   * Initializes the Bot.
   */
  void _init() {
    if (_initCalled) {
      return;
    }

    _initCalled = true;
    _initTime = new DateTime.now().millisecondsSinceEpoch;

    if (httpClient == null) {
      httpClient = new http.Client();
    }

    if (_conn == null) {
      _conn = new Receiver(_port);

      _eventSub = _conn.listen((it) {
        if (it["exception"] != null) {
          var e = new PluginException(it["exception"]["message"]);
          if (_exceptionHandlers.isNotEmpty) {
            for (var handler in _exceptionHandlers) {
              handler(e);
            }
          } else {
            throw e;
          }
        }

        if (it["event"] != null) {
          _handleEvent(it);
        }
      });

      var sub;
      sub = on("shutdown").listen((_) {
        httpClient.close();
        for (var action in _shutdown) {
          action();
        }

        for (var controller in _controllers.values) {
          controller.close();
        }

        _eventSub.cancel();

        for (var s in _subs) {
          s.cancel();
        }

        for (var storage in _storages) {
          storage.destroy();
        }

        sub.cancel();

        _isShutdown = true;
      });

      _conn.listenIntercom((plugin, data) {
        for (var handler in _pluginEventHandlers) {
          handler(plugin, data);
        }
      });

      _conn.listenRequest((request) {
        if (!request.command.startsWith("__") && _methods.containsKey(request.command)) {
          _methods[request.command](new RemoteCall(request));
        }

        if (request.command.startsWith("__")) {
          var name = request.command.substring(2);

          if (name == "getRemoteMethods") {
            request.reply({
              "value": _myMethods.values
            });
          } else if (name == "getRegisteredCommands") {
            request.reply({
              "value": _bot._myCommands.map((command) {
                return {
                  "name": command.name,
                  "description": command.description,
                  "plugin": command.plugin,
                  "usage": command.usage
                };
              }).toList()
            });
          }
        }
      });
    }

    if (_bot == null) {
      _bot = new BotConnector(this);
    }

    for (var action in _readyActions) {
      action();
    }

    /* Discover Annotations */
    List<FunctionAnnotation<Command>> cmds = findFunctionAnnotations(Command);
    List<FunctionAnnotation<EventHandler>> handlers = findFunctionAnnotations(EventHandler);
    Map<Type, Function> events = {
      OnJoin: getBot().onJoin,
      OnPart: getBot().onPart,
      OnBotJoin: getBot().onBotJoin,
      OnBotPart: getBot().onBotPart,
      OnMessage: getBot().onMessage,
      OnCTCP: getBot().onCTCP,
      OnNotice: getBot().onNotice,
      OnAction: getBot().onAction,
      OnQuit: getBot().onQuit,
      OnQuitPart: getBot().onQuitPart,
      OnBotReady: getBot().onReady,
      OnCommand: getBot().onCommand
    };

    for (var c in cmds) {
      getBot().command(c.metadata.name, (e) {
        c.invoke([e]);
      }, permission: c.metadata.permission, usage: c.metadata.usage, description: c.metadata.description, allowVariables: c.metadata.allowVariables);
    }

    for (var handler in handlers) {
      EventHandler h = handler.metadata;
      var hasParam = handler.mirror.parameters.isNotEmpty;

      on(h.event).listen((e) {
        if (hasParam) {
          handler.invoke([e]);
        } else {
          handler.invoke([]);
        }
      });
    }

    for (var type in events.keys) {
      var functions = findFunctionAnnotations(type);
      var vars = reflectClass(type).declarations.values.where((it) => it is VariableMirror && it.isFinal && !it.isStatic).toList();
      var map = <Symbol, dynamic>{};

      for (var x in functions) {
        var instance = reflect(x.metadata);
        for (var v in vars) {
          var i = instance.getField(v.simpleName);
          map[v.simpleName] = i.reflectee;
        }

        var hasParam = x.mirror.parameters.isNotEmpty;

        Function.apply(events[type], [hasParam ? (e) => x.invoke([e]) : (_) => x.invoke([])], map);
      }
    }

    for (FunctionAnnotation<RemoteMethod> a in findFunctionAnnotations(RemoteMethod)) {
      if (a.mirror.parameters.length == 1 && MirrorSystem.getName(a.mirror.parameters.first.simpleName) == "call") {
        addRemoteMethod(a.metadata.name != null ? a.metadata.name : MirrorSystem.getName(a.mirror.simpleName), (call) {
          a.invoke([call]);
        });
      } else {
        _addPluginMethod(this, currentMirrorSystem().isolate.rootLibrary, a.mirror);
      }
    }

    for (var variable in findVariablesAnnotation(PluginInstance)) {
      currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, this);
    }

    for (var variable in findVariablesAnnotation(BotInstance)) {
      currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, getBot());
    }

    for (var s in findFunctionAnnotations(Start)) {
      s.invoke([]);
    }

    for (var s in findFunctionAnnotations(Shutdown)) {
      onShutdown(() {
        s.invoke([]);
      });
    }

    for (var variable in findVariablesAnnotation(PluginStorage)) {
      PluginStorage m = variable.metadata.firstWhere((it) => it.type.isAssignableTo(reflectClass(PluginStorage))).reflectee;
      currentMirrorSystem().isolate.rootLibrary.setField(variable.simpleName, getStorage(m.name, group: m.group, saveOnChange: m.saveOnChange));
    }

    var httpEndpoints = findFunctionAnnotations(HttpEndpoint);
    var websocketEndpoints = findFunctionAnnotations(WebSocketEndpoint);
    var defaultEndpoints = findFunctionAnnotations(DefaultEndpoint);

    if (defaultEndpoints.isNotEmpty && defaultEndpoints.length != 1) {
      throw new Exception("A plugin cannot have more than one default HTTP Endpoint.");
    }

    if (httpEndpoints.isNotEmpty || websocketEndpoints.isNotEmpty) {
      createHttpRouter().then((router) {
        for (var e in httpEndpoints) {
          var path = e.metadata.path;

          if (e.parameters.length == 1) {
            router.addRoute(path, (req) {
              e.invoke([req]);
            });
          } else if (e.parameters.length == 2) {
            router.addRoute(path, (req) {
              e.invoke([req, req.response]);
            });
          } else {
            throw new Exception("HTTP Endpoint has an invalid number of parameters");
          }
        }

        for (var e in websocketEndpoints) {
          var path = e.metadata.path;
          router.addWebSocketEndpoint(path, (socket) {
            e.invoke([socket]);
          });
        }

        if (defaultEndpoints.isNotEmpty) {
          var de = defaultEndpoints.first;

          if (de.parameters.length == 1) {
            router.defaultRoute((req) {
              de.invoke([req]);
            });
          } else if (de.parameters.length == 2) {
            router.defaultRoute((req) {
              de.invoke([req, req.response]);
            });
          } else {
            throw new Exception("Default HTTP Endpoint has an invalid number of parameters");
          }
        }
      });
    }

    callMethod("__initialized", true);
  }

  bool _initCalled = false;

  /**
   * Gets a Storage instance with the given name provided by [storageName].
   *
   * If [group] is provided it will be stored with that group.
   */
  Storage getStorage(String storageName, {String group, bool saveOnChange: true}) {
    _init();
    if (group == null) group = name;

    var file = new File("data/${group}/${storageName}.json").absolute;
    var existing = _storages.firstWhere((it) => it.path == file.path, orElse: () => null);

    if (existing != null) {
      return existing;
    }

    var storage = new Storage(file.path, saveOnChange: saveOnChange);
    storage.load();
    _storages.add(storage);
    return storage;
  }

  /**
   * Registers a method [name] to [handler].
   *
   * [metadata] is data to carry with the method.
   */
  void addRemoteMethod(String name, RemoteCallHandler handler, {Map<String, dynamic> metadata: const {}}) {
    _init();

    if (name.startsWith("__")) {
      log("WARNING: Remote methods starting with '__' are reserved for internal use. Not adding remote method.");
      return;
    }

    _methods[name] = handler;
    _myMethods[name] = new RemoteMethodInfo(name, metadata: metadata);
  }

  /**
   * Fetches Plugin Methods for the given [plugin].
   */
  Future<List<RemoteMethodInfo>> getRemoteMethods(String plugin) {
    return callRemoteMethod(plugin, "__getRemoteMethods");
  }

  /**
   * Calls a Plugin Method.
   *
   * [plugin] is the target plugin.
   * [method] is the method name.
   * [arguments] are optional arguments.
   */
  Future<dynamic> callRemoteMethod(String plugin, String method, [dynamic arguments]) {
    var data = {
      "value": arguments
    };

    return callMethod("makePluginRequest", {
      "plugin": plugin,
      "command": method,
      "data": data
    });
  }

  /**
   * Handles Plugin Events.
   *
   * If [plugin] is provided the handler is called only for that plugin.
   */
  void onPluginEvent(PluginEventHandler handler, {String plugin}) {
    _init();

    _pluginEventHandlers.add((name, data) {
      if (plugin == null || name == plugin) {
        handler(name, data);
      }
    });
  }

  Future<Map<String, dynamic>> _get(String command, [Map<String, dynamic> data]) {
    _init();

    if (data == null) data = {};
    return _conn.get(command, data);
  }

  /**
   * Calls a Bot Method.
   *
   * [name] is the method name.
   * [arguments] is an optional argument.
   */
  Future<dynamic> callMethod(String name, [dynamic arguments]) {
    var data = {
      "value": arguments
    };

    return _get(name, data).then((response) {
      if (!response.containsKey("exception")) {
        return response["value"];
      } else {
        var e = new Exception(response["exception"]["message"]);
        throw e;
      }
    });
  }

  /**
   * Logs a Message to the Console.
   */
  void log(String message) {
    _init();

    print("[${displayName}] ${message}");
  }

  int _initTime;

  bool _isServerListening = false;

  /**
   * Starts an HTTP Server then create an HTTP Router.
   */
  Future<HttpRouter> createHttpRouter() {
    return startHttpServer().then((server) {
      return new HttpRouter(server);
    });
  }

  /**
   * Starts an HTTP Server that is forwarded through the main bot server.
   */
  Future<HttpServer> startHttpServer() {
    if (_isServerListening) {
      throw new Exception("Server is already listening.");
    }

    _isServerListening = true;

    return HttpServer.bind("0.0.0.0", 0).then((server) {
      httpServer = server;

      var startTime = new DateTime.now();
      if (startTime.millisecondsSinceEpoch - _initTime >= 5000) {
        callMethod("forwardHttpPort", server.port);
      } else {
        new Future.delayed(new Duration(seconds: 5), () {
          callMethod("forwardHttpPort", server.port);
        });
      }

      onShutdown(() {
        callMethod("unforwardHttpPort", {});
        server.close();
      });

      return server;
    });
  }

  /**
   * Checks if the plugin provided by [name] is installed.
   */
  Future<bool> isPluginInstalled(String name) => getPlugins().then((plugins) {
    return plugins.contains(name);
  });

  /**
   * Gets the loaded plugins.
   */
  Future<List<String>> getPlugins() {
    return callMethod("getPlugins");
  }

  /**
   * Sends [command] and [data] to a target.
   *
   * If [plugin] is provided it is sent to the given plugin otherwise it is sent to the main bot.
   */
  void send(String command, Map<String, dynamic> data, {String plugin}) {
    _init();

    var request = {
      "command": command
    };

    request.addAll(data);

    if (plugin != null) {
      _conn.intercom(plugin, request);
    } else {
      _conn.send(request);
    }
  }

  /**
   * Gets this plugin's bot instance.
   */
  BotConnector getBot() {
    _init();
    return _bot;
  }

  Map<String, RemoteMethodInfo> _myMethods = {};
}

/**
 * A Handler for Plugin Exceptions
 */
typedef void PluginExceptionHandler(PluginException e);

/**
 * Wrapper for Plugin Exceptions
 */
class PluginException {
  final String message;

  PluginException(this.message);

  @override
  String toString() => message;
}
