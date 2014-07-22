part of bot;

class PluginCommunicator {

  final PluginManager pm;
  final CoreBot bot;

  PluginCommunicator(this.pm, this.bot);

  handle() {
    _handleRequests();
    _handleNormals();
    _handleEventListeners();
  }

  _handleRequests() {
    pm.listenAllRequest((plugin, request) {
      switch (request.command) {
        case "networks":
          request.reply({
            "networks": bot.bots
          });
          break;
        default:
          throw new Exception("${plugin} sent an invalid request: ${request.command}");
          break;
      }
    });
  }

  _handleNormals() {
    pm.listenAll((String plugin, Map _data) {
      var m = new VerificationManager(plugin, _data);
      var b = bot[m['network']];
      var c = m['command'];
      if (c != null) {
        m.type = c;
      }
      switch (c) {
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
        default:
          throw new Exception("$plugin sent an invalid command: $c");
      }
    });
  }

  _handleEventListeners() {
    bot.bots.forEach((String network) {
      Bot b = bot[network];
      b.client.register((IRC.MessageEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "message";
        data['target'] = e.target;
        data['from'] = e.from;
        data['private'] = e.isPrivate;
        data['message'] = e.message;
        pm.sendAll(data);
      });

      b.client.register((IRC.CommandEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "command";
        data['target'] = e.target;
        data['from'] = e.from;
        data['private'] = e.isPrivate;
        data['message'] = e.message;

        data['command'] = e.command;
        data['args'] = e.args;
        pm.sendAll(data);
      });

      b.client.register((IRC.JoinEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "join";
        data['channel'] = e.channel.name;
        pm.sendAll(data);
      });

      b.client.register((IRC.PartEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "part";
        data['channel'] = e.channel.name;
        pm.sendAll(data);
      });

      b.client.register((IRC.BotJoinEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "bot-join";
        data['channel'] = e.channel.name;
        pm.sendAll(data);
      });

      b.client.register((IRC.BotPartEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "bot-part";
        data['channel'] = e.channel.name;
        pm.sendAll(data);
      });

      b.client.register((IRC.ReadyEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "ready";
        pm.sendAll(data);
      });

      b.client.register((IRC.InviteEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "invite";
        data['user'] = e.user;
        data['channel'] = e.channel;
        pm.sendAll(data);
      });

      b.client.register((IRC.NoticeEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "notice";
        data['target'] = e.target;
        data['from'] = e.from;
        data['private'] = e.isPrivate;
        data['message'] = e.message;
        pm.sendAll(data);
      });

      b.client.register((IRC.TopicEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "topic";
        data['channel'] = e.channel.name;
        data['topic'] = e.topic;
        pm.sendAll(data);
      });

      b.client.register((IRC.ConnectEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "connect";
        pm.sendAll(data);
      });

      b.client.register((IRC.DisconnectEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "disconnect";
        pm.sendAll(data);
      });
    });
  }
}
