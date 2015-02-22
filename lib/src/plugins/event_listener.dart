part of polymorphic.bot;

class IrcEventListener {
  final PluginCommunicator com;
  final String network;

  IrcEventListener(this.network, this.com);

  void handle() {
    Bot b = com.bot[network];

    b.client.register((IRC.KickEvent e) {
      if (e.channel != null && e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("kick");

      data["kicker"] = e.by;
      data["reason"] = e.reason;
      data["user"] = e.user;
      data["channel"] = e.channel.name;

      com.pm.sendAll(data);
    });

    b.client.register((IRC.MOTDEvent e) {
      var data = common("motd");
      data["message"] = e.message;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.ServerSupportsEvent e) {
      var data = common("supports");

      data["supported"] = e.supported;

      com.pm.sendAll(data);
    });

    b.client.register((IRC.NickChangeEvent e) {
      var data = common("nick-change");

      data["original"] = e.original;
      data["now"] = e.now;

      com.pm.sendAll(data);
    });

    b.client.register((IRC.MessageEvent e) {
      if (e.channel != null && e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("message");

      var pings = <String>["${e.client.nickname}: ", "${e.client.nickname}, "];
      var isCommand = b.getMessagePrefix(e.channel.name, e.message) != null;
      data["command"] = isCommand;
      if (pings.any((it) => e.message.startsWith(it))) {
        var p = pings.firstWhere((it) => e.message.startsWith(it));
        data['msgnoping'] = e.message.substring(p.length);
        data['ping'] = true;
      } else {
        data['ping'] = false;
        data['msgnoping'] = e.message;
      }

      commonSendable(data, e);
      com.pm.sendAll(data);
    });

    b.client.register((IRC.CTCPEvent event) {
      if (event.target == "#bot-communication") {
        return;
      }

      var data = common("ctcp");
      data["target"] = event.target;
      data["user"] = event.user;
      data["message"] = event.message;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.CommandEvent e) async {
      var username = await b.getUsername(e.from);

      if (e.channel != null && e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("command");
      commonSendable(data, e);

      data['command'] = e.command;
      data['args'] = e.args;
      data['username'] = username;
      com.pm.sendAll(data);

      Globals.analytics.sendEvent("irc", "command", label: "IRC Command");
      Globals.analytics.sendEvent("command", e.command, label: "${e.command} command");
    });

    b.client.register((IRC.NickInUseEvent e) {
      var data = common("nick-in-use");

      data["original"] = e.original;

      com.pm.sendAll(data);
    });



    b.client.register((IRC.PongEvent e) {
      var data = common("pong");

      data['message'] = e.message;

      com.pm.sendAll(data);
    });

    b.client.register((IRC.NoticeEvent e) {
      if (e.channel != null && e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("notice");
      commonSendable(data, e);
      com.pm.sendAll(data);
    });

    b.client.register((IRC.JoinEvent e) {
      if (e.channel == null) return;

      if (e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("join");
      data['channel'] = e.channel.name;
      data['user'] = e.user;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.PartEvent e) {
      if (e.channel == null) return;

      if (e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("part");
      data['channel'] = e.channel.name;
      data['user'] = e.user;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.BotJoinEvent e) {
      if (e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("bot-join");
      data['channel'] = e.channel.name;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.BotPartEvent e) {
      if (e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("bot-part");
      data['channel'] = e.channel.name;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.ReadyEvent e) {
      var data = common("ready");
      com.pm.sendAll(data);
    });

    b.client.register((IRC.InviteEvent e) {
      if (e.channel == "#bot-communication") {
        return;
      }

      var data = common("invite");
      data['user'] = e.user;
      data['channel'] = e.channel;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.ErrorEvent e) {
      var data = common("error");

      data["message"] = e.message;
      data["type"] = e.type;

      com.pm.sendAll(data);
    });

    b.client.register((IRC.LineSentEvent e) {
      var data = common("line-sent");
      data["line"] = e.line;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.LineReceiveEvent e) {
      var data = common("line-receive");
      data["line"] = e.line;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.TopicEvent e) {
      if (e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("topic");
      data['channel'] = e.channel.name;
      data['topic'] = e.topic;
      data['user'] = e.user;
      data['oldTopic'] = e.oldTopic;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.ConnectEvent e) {
      var data = common("connect");
      com.pm.sendAll(data);
    });

    b.client.register((IRC.QuitEvent e) {
      var data = common("quit");
      data["user"] = e.user;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.QuitPartEvent e) {
      if (e.channel == null) return;

      var data = common("quit-part");
      data["user"] = e.user;
      data["channel"] = e.channel.name;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.DisconnectEvent e) {
      var data = common("disconnect");
      com.pm.sendAll(data);
    });

    b.client.register((IRC.ModeEvent e) {
      if (e.channel != null && e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("mode");
      if (e.channel != null) {
        data['channel'] = e.channel.name;
      }
      data['mode'] = e.mode;
      data['user'] = e.user;
      com.pm.sendAll(data);
    });

    // deprecated
    b.client.register((IRC.WhoisEvent event) {
      var data = common("whois");
      data['member_in'] = event.member_in;
      data['op_in'] = event.operatorChannels;
      data['operatorChannels'] = event.operatorChannels;
      data['voice_in'] = event.voicedChannels;
      data['voicedChannels'] = event.voicedChannels;
      data['username'] = event.username;
      data['server_operator'] = event.isServerOperator;
      data['isServerOperator'] = event.isServerOperator;
      data['realname'] = event.realname;
      data['nickname'] = event.nickname;
      com.pm.sendAll(data);
    });
  }

  Map common(String event) {
    return {
      'type': "event",
      'network': network,
      'event': event
    };
  }

  void commonSendable(Map data, dynamic event) {
    data['target'] = event.target;
    data['from'] = event.from;
    data['private'] = event.isPrivate;
    data['message'] = event.message;
  }
}
