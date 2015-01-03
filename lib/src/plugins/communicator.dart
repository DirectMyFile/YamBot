part of polymorphic.bot;

class PluginCommunicator {
  final CoreBot bot;
  final PluginHandler handler;

  PluginManager get pm => handler.pm;
  
  PluginCommunicator(this.bot, this.handler) {
    _handleEventListeners();
  }
  
  void initialStart() {
    var host = bot.config["http"]["host"] != null ? bot.config["http"]["host"] : "0.0.0.0";
    var port = bot.config["http"]["port"];
    
    HttpServer.bind(host, port).then((server) {
      server.listen((request) {
        var segments = request.uri.pathSegments;
        if (segments.isNotEmpty && _httpPorts.containsKey(segments[0])) {
          var segs = []..addAll(segments)..removeAt(0);
          var path = segs.join("/");
          if (path.trim().isEmpty) {
            path = "/";
          }
          HttpHelper.forward(request, path, InternetAddress.ANY_IP_V4.address, _httpPorts[segments[0]]);
        } else {
          request.response.statusCode = 404;
          request.response.writeln("ERROR: 404 not found.");
          request.response.close();
        }
      });
    });
  }
  
  Map<String, int> _httpPorts = {};

  void handle() {
    if (bot.config["http"] == null || bot.config["http"]["port"] == null) {
      print("[HTTP] ERROR: No HTTP Port Configured.");
      exit(1);
    }
    
    _handleRequests();
    _handleNormals();
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
          
        case "isUserABot":
          var network = m['network'];
          var user = m['user'];
          bot[network].isUserBot(user).then((isBot) {
            request.reply({
              "value": isBot
            });
          });
          break;
        
        case "plugins":
          request.reply({
            "names": pm.plugins.toList()
          });
          break;
        
        case "plugin-commands":
          String pluginName = m['plugin'];
          var pubspec = pm.plugin(pluginName).pubspec;
          
          if (pubspec['plugin'] == null || pubspec['plugin']['commands'] == null) {
            request.reply(null);
          } else {
            Map<String, Map<String, dynamic>> commands = pubspec['plugin']['commands'];
            Map<String, Map<String, dynamic>> converted = {};
            
            for (var name in commands.keys) {
               converted[name] = {
                "usage": commands[name]['usage'],
                "description": commands[name]['description']
               };
            }
            
            request.reply(converted);
          }
          break;
        case "command-exists":
          String name = m['command'];
          List<String> cmdNames = [];

          for (var pluginName in pm.plugins) {
            var plugin = pm.plugin(pluginName);

            var pubspec = plugin.pubspec;

            if (pubspec['plugin'] == null || pubspec['plugin']['commands'] == null) {
              request.reply(null);
            } else {
              Map<String, Map<String, dynamic>> commands = pubspec['plugin']['commands'];
              Map<String, Map<String, dynamic>> converted = {};

              for (var name in commands.keys) {
                cmdNames.add(name);
              }
            }
          }

          var exists = cmdNames.contains(name);

          request.reply({
            "exists": exists
          });
          break;
        
        case "setup-plugin-http":
          var port = request.data["port"];
          _httpPorts[plugin] = port;
          break;
          
        case "shutdown-plugin-http":
          _httpPorts.remove(plugin);
          break;
          
        case "command-info":
          var allCommands = {};
          
          for (var pluginName in pm.plugins) {
            var plugin = pm.plugin(pluginName);

            var pubspec = plugin.pubspec;

            if (pubspec['plugin'] == null || pubspec['plugin']['commands'] == null) {
              request.reply(null);
            } else {
              Map<String, Map<String, dynamic>> commands = pubspec['plugin']['commands'];
              Map<String, Map<String, dynamic>> converted = {};

              for (var name in commands.keys) {
                converted[name] = {
                  "plugin": pluginName,
                  "usage": commands[name]['usage'],
                  "description": commands[name]['description']
                };
              }

              allCommands.addAll(converted);
            }
          }
          
          if (m.data.containsKey("command")) {
            request.reply(allCommands[m["command"]]);
          } else {
            request.reply(allCommands);
          }

          request.reply(allCommands[m['command']]);

          break;
        case "permission":
          var node = m['node'];
          var net = m['network'];
          var nick = m['nick'];
          var target = m['target'];
          var notify = request.data['notify']; // optional field
          bot[net].authManager.hasPermission(plugin, nick, node).then((bool has) {
            if (!has) {
              var b = bot[net];
              if (notify == null || m['notify']) {
                b.client.sendMessage(target,
                  "$nick> You are not authorized to perform this action (missing $plugin.$node)");
              }
            }
            request.reply({ "has": has });
          });
          break;
          
        case "channel":
          var net = request.data['network'];
          var chan = request.data['channel'];
          var channel = bot._clients[net].client.getChannel(chan);
          request.reply({
            "name": channel.name,
            "ops": channel.ops,
            "voices": channel.voices,
            "members": channel.members,
            "owners": channel.owners,
            "halfops": channel.halfops,
            "topic": channel.topic
          });
          break;
        case "whois":
          var net = m['network'];
          var user = m['user'];
          bot[net].client.whois(user).then((event) {
            var memberIn  = () {
              var list = <String>[];
              list.addAll(event.builder.channels.where((i) =>
                  !event.builder.opIn.contains(i) &&
                  !event.builder.voiceIn.contains(i) &&
                  !event.builder.halfOpIn.contains(i) &&
                  !event.builder.ownerIn.contains(i)
              ));
              return list; 
            }();
            request.reply({
              "away": event.away,
              "awayMessage": event.awayMessage,
              "isServerOperator": event.isServerOperator,
              "hostname": event.hostname,
              "idle": event.idle,
              "idleTime": event.idleTime,
              "memberIn": memberIn,
              "operatorIn": event.builder.opIn,
              "channels": event.builder.channels,
              "ownerIn": event.builder.ownerIn,
              "halfOpIn": event.builder.halfOpIn,
              "voiceIn": event.builder.voiceIn,
              "nickname": event.builder.nickname,
              "realname": event.builder.realname,
              "username": event.builder.username
            });
          });
          break;
        default:
          throw new Exception("${plugin} sent an invalid request: ${request.command}");
      }
    });
  }

  void _handleNormals() {
    pm.listenAll((String plugin, Map _data) {
      try {
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
            b.client.sendMessage(target, msg);
            break;
          case "ctcp":
            var target = m["target"];
            var msg = m["message"];
            
            b.client.sendCTCP(target, msg);
            break;
          case "notice":
            var msg = m['message'] as String;
            var target = m['target'] as String;
            
            b.client.sendNotice(target, msg);
            break;
          case "action":
            var msg = m['message'] as String;
            var target = m['target'] as String;
            b.client.sendAction(target, msg);
            break;
          case "reload-plugins":
            handler.reloadPlugins();
            break;
          case "join":
            var channel = m['channel'] as String;
            b.client.join(channel);
            break;
          case "part":
            var channel = m['channel'] as String;
            b.client.part(channel);
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
          case "clear-bot-memory":
            b.clearBotMemory();
            break;
          case "quit":
            var reason = _data['reason'] != null ? m['reason'] : "Bot Quitting";
            b.client.disconnect(reason: reason);
            break;
          case "broadcast":
            if (!handler.isPluginElevated(plugin)) {
              throw new Exception("Plugin must declare itself as being elevated in order to broadcast a message to all plugins.");
            }
            
            var data = m['data'];
            pm.sendAll(data);
            break;
          case "stop-bot":
            var futures = [];
            
            for (var botname in bot.bots) {
              var completer = new Completer();
              futures.add(completer.future);
              var it = bot._clients[botname];
              it.client.register((IRC.DisconnectEvent event) {
                completer.complete();
              }, once: true);
              it.client.disconnect();
            }
            
            Future.wait(futures).then((_) {
              handler.killPlugins();
              exit(0);
            });
            
            new Future.delayed(new Duration(seconds: 5), () {
              exit(0);
            });
            break;
          case "whois":
            var user = m['user'];
            b.client.send("WHOIS ${user}");
            break;
          default:
            throw new Exception("$plugin sent an invalid command: $command");
        }
      } on Exception catch (e) {
        pm.send(plugin, {
          "exception": {
            "message": e.toString()
          }
        });
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
    
    b.client.register((IRC.CTCPEvent event) {
      var data = common("ctcp");
      data["target"] = event.target;
      data["user"] = event.user;
      data["message"] = event.message;
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
      data['user'] = e.user;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.PartEvent e) {
      var data = common("part");
      data['channel'] = e.channel.name;
      data['user'] = e.user;
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

    b.client.register((IRC.ModeEvent e) {
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
