part of polymorphic.bot;

class PluginCommunicator {

  final PluginManager pm;
  final CoreBot bot;

  PluginCommunicator(this.pm, this.bot);

  void handle() {
    _handleRequests();
    _handleNormals();
    _handleEventListeners();
  }

  void _handleRequests() {
    pm.listenAllRequest((plugin, request) {
      var m = new VerificationManager(plugin, request.data);
      switch (request.command) {
        case "networks":
          request.reply({
            "networks": bot.bots
          });
          break;
        case "config":
          request.reply({
            "config": bot.config
          });
          break;
        case "request":
          var plugin = m['plugin'];
          var command = m['command'];
          var data = m['data'];
          pm.get(plugin, command, data).then((response) {
            request.reply(response);
          });
          break;
        case "permission":
          var node = m['node'];
          var net = m['network'];
          var nick = m['nick'];
          var target = m['target'];
          bot[net].authManager.hasPermission(plugin, nick, node).then((bool has) {
            if (!has) {
              var b = bot[net];
              b.client.message(target,
                  "$nick> You are not authorized to perform this action (missing $plugin.$node)");
            }
            request.reply({ "has": has });
          });
          break;
        default:
          throw new Exception("${plugin} sent an invalid request: ${request.command}");
          break;
      }
    });
  }

  void _handleNormals() {
    pm.listenAll((String plugin, Map _data) {
      var m = new VerificationManager(plugin, _data);
      var b = bot[m['network']];
      var command = m['command'];
      if (command != null) {
        m.type = command;
      }
      switch (command) {
        case "message":
          var msg = m['message'] as String;
          var target = m['target'] as String;
          b.client.message(target, msg);
          break;
        case "notice":
          var msg = m['message'] as String;
          var target = m['target'] as String;
          b.client.notice(target, msg);
          break;
        case "action":
          var msg = m['message'] as String;
          var target = m['target'] as String;
          b.client.action(target, msg);
          break;
        case "join":
          var channel = m['channel'] as String;
          b.client.join(channel);
          break;
        case "part":
          var channel = m['channel'] as String;
          b.client.join(channel);
          break;
        case "raw":
          var line = m['line'] as String;
          b.client.send(line);
          break;
        case "send":
          var plugin = m['plugin'];
          var data = m['data'];
          pm.send(plugin, data);
          break;
        case "update-config":
          var config = m['config'];
          bot.config.clear();
          bot.config.addAll(config);
          break;
        default:
          throw new Exception("$plugin sent an invalid command: $command");
      }
    });
  }

  void _handleEventListeners() {
    bot.bots.forEach((String network) {
      var nel = new NetworkEventListener(network, this);
      nel.handle();
    });
  }
}

class NetworkEventListener {

  final PluginCommunicator com;
  final String network;

  NetworkEventListener(this.network, this.com);

  void handle() {
    Bot b = com.bot[network];
    b.client.register((IRC.MessageEvent e) {
      var data = common("message");
      commonSendable(data, e);
      com.pm.sendAll(data);
    });

    b.client.register((IRC.CommandEvent e) {
      var data = common("command");
      commonSendable(data, e);

      data['command'] = e.command;
      data['args'] = e.args;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.NoticeEvent e) {
      var data = common("notice");
      commonSendable(data, e);
      com.pm.sendAll(data);
    });

    b.client.register((IRC.JoinEvent e) {
      var data = common("join");
      data['channel'] = e.channel.name;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.PartEvent e) {
      var data = common("part");
      data['channel'] = e.channel.name;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.BotJoinEvent e) {
      var data = common("bot-join");
      data['channel'] = e.channel.name;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.BotPartEvent e) {
      var data = common("bot-part");
      data['channel'] = e.channel.name;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.ReadyEvent e) {
      var data = common("ready");
      com.pm.sendAll(data);
    });

    b.client.register((IRC.InviteEvent e) {
      var data = common("invite");
      data['user'] = e.user;
      data['channel'] = e.channel;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.TopicEvent e) {
      var data = common("topic");
      data['channel'] = e.channel.name;
      data['topic'] = e.topic;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.ConnectEvent e) {
      var data = common("connect");
      com.pm.sendAll(data);
    });

    b.client.register((IRC.DisconnectEvent e) {
      var data = common("disconnect");
      com.pm.sendAll(data);
    });
  }

  Map common(String event) {
    return {
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
