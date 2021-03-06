part of polymorphic.api;

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
  Possible checkPermission(String network, String target, String user, String node, [bool notify]) {
    var p = new PossibleCreator();

    Map params = {
      "node": node,
      "network": network,
      "user": user,
      "target": target,
      "notify": notify
    };

    plugin.callMethod("checkPermission", params).then((has) {
      if (has) {
        p.complete(true);
      }
    });

    return p.possible;
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
  void setMode(String network, String mode, {String user, String channel}) {
    plugin.callMethod("setMode", {
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
    setMode(network, "+o", channel: channel, user: user);
  }

  /**
   * Deops [user] in [channel] on [network].
   */
  void deop(String network, String channel, String user) {
    setMode(network, "-o", channel: channel, user: user);
  }

  /**
   * Voices [user] in [channel] on [network].
   */
  void voice(String network, String channel, String user) {
    setMode(network, "+v", channel: channel, user: user);
  }

  /**
   * Devoices [user] in [channel] on [network].
   */
  void devoice(String network, String channel, String user) {
    setMode(network, "-v", channel: channel, user: user);
  }

  /**
   * HalfOps [user] in [channel] on [network].
   */
  void halfOp(String network, String channel, String user) {
    setMode(network, "+h", channel: channel, user: user);
  }

  /**
   * DeHalfOps [user] in [channel] on [network].
   */
  void dehalfOp(String network, String channel, String user) {
    setMode(network, "-h", channel: channel, user: user);
  }

  /**
   * Owners [user] in [channel] on [network].
   */
  void owner(String network, String channel, String user) {
    setMode(network, "+q", channel: channel, user: user);
  }

  /**
   * Deowners [user] in [channel] on [network].
   */
  void deowner(String network, String channel, String user) {
    setMode(network, "-q", channel: channel, user: user);
  }

  /**
   * Quiets [user] in [channel] on [network].
   */
  void quiet(String network, String channel, String user) {
    setMode(network, "+q", channel: channel, user: user);
  }

  /**
   * Unquiets [user] in [channel] on [network].
   */
  void unquiet(String network, String channel, String user) {
    setMode(network, "-q", channel: channel, user: user);
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
    setMode(network, "+b", channel: channel, user: user);
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
    setMode(network, "-b", channel: channel, user: user);
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

  Future<List<String>> listChannelUsers(String network, String name) {
    return plugin.callMethod("getChannelUsers", {
      "network": network,
      "channel": name
    });
  }

  Future<List<String>> listChannelOps(String network, String name) {
    return plugin.callMethod("getChannelOps", {
      "network": network,
      "channel": name
    });
  }

  Future<List<String>> listChannelVoices(String network, String name) {
    return plugin.callMethod("getChannelVoices", {
      "network": network,
      "channel": name
    });
  }

  Future<List<String>> listChannelMembers(String network, String name) {
    return plugin.callMethod("getChannelMembers", {
      "network": network,
      "channel": name
    });
  }

  Future<bool> hasPermission(String network, String user, String permission, {String plugin}) {
    if (plugin == null) {
      plugin = this.plugin.name;
    }

    return this.plugin.callMethod("hasPermission", {
      "network": network,
      "user": user,
      "permission": permission,
      "plugin": plugin
    });
  }

  Future<String> getVersion() {
    return plugin.callMethod("getVersion");
  }

  Future<List<String>> listChannelOwners(String network, String name) {
    return plugin.callMethod("getChannelOwners", {
      "network": network,
      "channel": name
    });
  }

  Future<List<String>> listChannelHalfOps(String network, String name) {
    return plugin.callMethod("getChannelHalfOps", {
      "network": network,
      "channel": name
    });
  }

  void setChannelTopic(String network, String name, String topic) {
    plugin.callMethod("setChannelTopic", {
      "network": network,
      "channel": name,
      "topic": topic
    });
  }

  Future<String> getChannelTopic(String network, String name) {
    return plugin.callMethod("getChannelTopic", {
      "network": network,
      "channel": name
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

  void onNickChange(NickChangeHandler handler) {
    var sub = plugin.on("nick-change").map((it) {
      var network = it["network"];
      var original = it["original"];
      var now = it["now"];

      return new NickChangeEvent(this, network, original, now);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onNickInUse(NickInUseHandler handler) {
    var sub = plugin.on("nick-in-use").map((it) {
      return new NickInUseEvent(this, it["network"], it["original"]);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onServerSupports(ServerSupportsHandler handler) {
    var sub = plugin.on("supports").map((it) {
      return new ServerSupportsEvent(this, it["network"], it["supported"]);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onMOTD(MOTDHandler handler) {
    var sub = plugin.on("motd").map((it) {
      return new MOTDEvent(this, it["network"], it["message"]);
    }).listen((event) {
      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  void onKick(KickHandler handler) {
    var sub = plugin.on("kick").map((it) {
      return new KickEvent(this, it["network"], it["channel"], it["user"], it["kicker"], it["reason"]);
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
    if (pattern is String) {
      if (regex) {
        pattern = new RegExp(pattern.toString(), caseSensitive: caseSensitive);
      } else {
        pattern = new RegExp(escapeRegex(pattern.toString()), caseSensitive: caseSensitive);
      }
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
      var isCommand = it["command"];

      return new MessageEvent(this, network, target, from, private, isPing, isCommand, message, match: match);
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
      var event = new TopicEvent(this, data["network"], data["channel"], data["user"], data["topic"], data["oldTopic"]);

      handler(event);
    });

    plugin.registerSubscription(sub);
  }

  Future<bool> isUserOn(String network, String user) {
    return plugin.callMethod("isUserOn", {
      "network": network,
      "user": user
    });
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
      var event = new ModeEvent(this, data["network"], data["channel"], data["user"], data["addedModes"], data["removedModes"]);

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
  void command(String name, CommandHandler handler, {String usage: "", String description: "Not Provided", String permission, bool allowVariables: false, bool randomize: false, bool notice: false}) {
    var info = new CommandInfo(plugin.name, name, usage, description);
    _myCommands.add(info);

    onCommand((CommandEvent event) {
      if (event.command != name) {
        return null;
      }

      if (permission != null) {
        var c = new Completer();
        event.require(permission, () {
          c.complete(handler(event));
        });

        return c.future.timeout(new Duration(seconds: 5), onTimeout: () {
          return null;
        });
      } else {
        return handler(event);
      }
    }, allowVariables: allowVariables, randomize: randomize, notice: notice);
  }

  void emitBotEvent(String event, Map<String, dynamic> data) {
    var map = {
      "event": event
    }..addAll(data);

    plugin.callMethod("emit", map);
  }

  sendFakeMessage(String network, String user, String target, String message) async {
    var e = {
      "network": network,
      "user": user,
      "target": target,
      "message": message
    };

    await plugin.callMethod("fakeMessage", e);
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

  void changeBotNickname(String network, String nick) {
    plugin.callMethod("changeBotNickname", {
      "network": network,
      "nickname": nick
    });
  }

  void onCommand(CommandHandler handler, {bool allowVariables: false, bool randomize: false, bool notice: false}) {
    var sub = plugin.on("command").listen((data) {
      String command = data['command'];
      List<String> args = data['args'];

      String user = data['from'];
      String channel = data['target'];
      String network = data['network'];
      String message = data['message'];
      String username = data['username'];

      void emit() {
        var event = new CommandEvent(
          this,
          network,
          command,
          message,
          user,
          channel,
          args,
          username,
          randomize: randomize
        );

        var result = handler(event);

        if (notice) {
          event < result;
        } else {
          event << result;
        }
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
