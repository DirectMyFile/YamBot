part of polymorphic.bot;

typedef PluginRequestHandler(String plugin, Request request);

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
        
        if (segments.length >= 2 && segments[0] == "plugin" && _httpPorts.containsKey(segments[1])) {
          var name = segments[1];
          var segs = []
              ..addAll(segments)
              ..removeAt(0)
              ..removeAt(0);
          var path = "/" + segs.join("/");
          HttpHelper.forward(request, Uri.parse("http://${InternetAddress.ANY_IP_V4.address}:${_httpPorts[name]}${path}"));
          return;
        }

        var response = request.response;

        if (request.uri.path.trim() == "/plugins.json") {
          if (request.method != "GET") {
            response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
            response.writeln("ERROR: Only GET is allowed here.");
            response.close();
          } else {
            response.statusCode = 200;
            response.writeln(encodeJSON(pm.plugins));
            response.close();
          }
        } else {
          response.statusCode = 404;
          response.writeln("ERROR: 404 not found.");
          response.close();
        }
      });
    });
  }

  Map<String, Polymorphic.RemoteCallHandler> _methods = {};
  Map<String, Polymorphic.RemoteMethodInfo> _methodInfo = {};

  void addBotMethod(String name, Polymorphic.RemoteCallHandler handler, {Map<String, dynamic> metadata: const {}, bool isVoid: false}) {
    _methods[name] = handler;
    _methodInfo[name] = new Polymorphic.RemoteMethodInfo(name, metadata: metadata, isVoid: isVoid);
  }

  JsonEncoder _jsonEncoder = new JsonEncoder.withIndent("  ");

  String encodeJSON(obj) {
    return _jsonEncoder.convert(obj);
  }

  Map<String, int> _httpPorts = {};

  void handle() {
    if (bot.config["http"] == null || bot.config["http"]["port"] == null) {
      print("[HTTP] ERROR: No HTTP Port Configured.");
      exit(1);
    }

    _addBotMethods();
    _handleRequests();

    pm.listenAll((plugin, data) {
      /* We don't use this anymore, everything is a method call */
    });
  }

  void _addBotMethods() {
    String getPluginName() => Zone.current["bot.plugin.method.plugin"];

    addBotMethod("getNetworks", (call) {
      call.reply(bot.bots);
    });

    addBotMethod("getConfig", (call) {
      call.reply(bot.config);
    });

    addBotMethod("makePluginRequest", (call) {
      var plugin = call.getArgument("plugin");
      var command = call.getArgument("command");
      var data = call.getArgument("data");

      pm.get(plugin, command, data).then((response) {
        call.request.reply(response);
      });
    });

    addBotMethod("getPlugins", (call) {
      call.reply(pm.plugins.toList());
    });
    
    addBotMethod("getBotNickname", (call) {
      call.reply(bot[call.getArgument("value")].client.nickname);
    });

    addBotMethod("isUserABot", (call) {
      var network = call.getArgument('network');
      var user = call.getArgument('user');
      bot[network].isUserBot(user).then((isBot) {
        call.reply(isBot);
      });
    });
    
    addBotMethod("restart", (call) {
      bot.restart();
    });

    addBotMethod("doesCommandExist", (call) {
      var name = call.getArgument("value");

      List<String> cmdNames = [];

      for (var pluginName in pm.plugins) {
        var plugin = pm.plugin(pluginName);

        var pubspec = plugin.pubspec;

        if (pubspec['plugin'] == null || pubspec['plugin']['commands'] == null) {
          call.reply(null);
        } else {
          Map<String, Map<String, dynamic>> commands = pubspec['plugin']['commands'];

          for (var name in commands.keys) {
            cmdNames.add(name);
          }
        }
      }

      var exists = cmdNames.contains(name);

      call.reply(exists);
    });

    addBotMethod("forwardHttpPort", (call) {
      var port = call.getArgument("value");

      _httpPorts[getPluginName()] = port;
    }, isVoid: true);

    addBotMethod("getPrefix", (call) {
      var network = call.getArgument("network");
      var channel = call.getArgument("channel");

      call.reply(bot[network].getPrefix(channel));
    });

    addBotMethod("unforwardHttpPort", (call) {
      _httpPorts.remove(getPluginName());
    }, isVoid: true);

    addBotMethod("getCommandInfo", (Polymorphic.RemoteCall call) {
      if (call.getArgument("plugin") != null) {
        pm.get(call.getArgument("plugin"), "__getRegisteredCommands", {}).then((result) {
          call.reply(result["value"]);
        });
      } else if (call.getArgument("command") != null) {
        var allCommands = {};
        var group = new FutureGroup();

        for (var p in pm.plugins) {
          group.add(pm.get(p, "__getRegisteredCommands", {}).then((result) {
            return result["value"];
          }));
        }

        group.future.then((all) {
          for (var a in all) {
            for (var c in a) {
              allCommands[c["name"]] = c;
            }
          }

          call.reply(allCommands[call.getArgument("command")]);
        });
      } else {
        var allCommands = {};
        var group = new FutureGroup();

        for (var p in pm.plugins) {
          group.add(pm.get(p, "__getRegisteredCommands", {}).then((result) {
            return result["value"];
          }));
        }

        group.future.then((all) {
          for (var a in all) {
            for (var c in a) {
              allCommands[c["name"]] = c;
            }
          }

          call.reply(allCommands);
        });
      }
    });
    
    addBotMethod("getChannelBuffer", (call) {
      var network = call.getArgument("network");
      var channel = call.getArgument("channel");
      
      call.reply(Buffer.get("${network}${channel}").map((it) {
        return it.toData();
      }).toList());
    });
    
    addBotMethod("appendChannelBuffer", (call) {
      var network = call.getArgument("network");
      var from = call.getArgument("from");
      var target = call.getArgument("target");
      var message = call.getArgument("message");
      Buffer.handle(network, new IRC.MessageEvent(bot[network].client, from, target, message));
    });

    addBotMethod("checkPermission", (call) {
      var node = call.getArgument('node');
      var net = call.getArgument('network');
      var user = call.getArgument('user');
      var target = call.getArgument('target');
      var notify = call.getArgument("notify", defaultValue: true);
      bot[net].authManager.hasPermission(getPluginName(), user, node).then((bool has) {
        if (!has) {
          var b = bot[net];
          if (notify == null || notify) {
            b.client.sendMessage(target, "$user> You are not authorized to perform this action (missing ${getPluginName()}.${node})");
          }
        }
        call.reply(has);
      });
    });

    addBotMethod("getChannel", (call) {
      var net = call.getArgument('network');
      var chan = call.getArgument('channel');
      var channel = bot._clients[net].client.getChannel(chan);

      if (channel == null) {
        call.reply(null);
        return;
      }

      call.reply({
        "name": channel.name,
        "ops": channel.ops,
        "voices": channel.voices,
        "members": channel.members,
        "owners": channel.owners,
        "halfops": channel.halfops,
        "topic": channel.topic
      });
    });

    addBotMethod("whois", (call) {
      var net = call.getArgument('network');
      var user = call.getArgument('user');
      bot[net].client.whois(user).then((event) {
        var memberIn = () {
          var list = <String>[];
          list.addAll(event.builder.channels.where((i) => !event.builder.opIn.contains(i) && !event.builder.voiceIn.contains(i) && !event.builder.halfOpIn.contains(i) && !event.builder.ownerIn.contains(i)));
          return list;
        }();

        call.reply({
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
    });

    addBotMethod("kick", (call) {
      var user = call.getArgument("user");
      var channel = call.getArgument("channel");
      var network = call.getArgument("network");
      var reason = call.getArgument("reason");

      bot[network].client.kick(bot[network].client.getChannel(channel), user, reason);
    });

    addBotMethod("mode", (call) {
      var user = call.getArgument("user");
      var channel = call.getArgument("channel");
      var network = call.getArgument("network");
      var mode = call.getArgument("mode");

      if (channel == null) {
        if (user != null) {
          bot[network].client.mode(mode, user: user);
        } else {
          bot[network].client.mode(mode);
        }
      } else {
        if (user != null) {
          bot[network].client.getChannel(channel).mode(mode, user);
        } else {
          bot[network].client.getChannel(channel).mode(mode);
        }
      }
    }, isVoid: true);

    addBotMethod("sendMessage", (call) {
      var network = call.getArgument("network");
      var target = call.getArgument("target");
      var message = call.getArgument("message");

      bot[network].client.sendMessage(target, message);
    }, isVoid: true);

    addBotMethod("sendNotice", (call) {
      var network = call.getArgument("network");
      var target = call.getArgument("target");
      var message = call.getArgument("message");

      bot[network].client.sendNotice(target, message);
    }, isVoid: true);

    addBotMethod("sendAction", (call) {
      var network = call.getArgument("network");
      var target = call.getArgument("target");
      var message = call.getArgument("message");

      bot[network].client.sendAction(target, message);
    }, isVoid: true);
    
    addBotMethod("emit", (call) {
      var e = call.getArgument("value");
      pm.sendAll({
        "type": "event"
      }..addAll(e));
    });

    addBotMethod("sendCTCP", (call) {
      var network = call.getArgument("network");
      var target = call.getArgument("target");
      var message = call.getArgument("message");

      bot[network].client.sendCTCP(target, message);
    }, isVoid: true);

    addBotMethod("joinChannel", (call) {
      var network = call.getArgument("network");
      var channel = call.getArgument("channel");

      bot[network].client.join(channel);
    }, isVoid: true);

    addBotMethod("partChannel", (call) {
      var network = call.getArgument("network");
      var channel = call.getArgument("channel");

      bot[network].client.part(channel);
    }, isVoid: true);

    addBotMethod("clearBotMemory", (call) {
      var network = call.getArgument("network");

      bot[network].clearBotMemory();
    }, isVoid: true);

    addBotMethod("sendRawLine", (call) {
      var network = call.getArgument("network");
      var line = call.getArgument("line");

      bot[network].client.send(line);
    }, isVoid: true);

    addBotMethod("reloadPlugins", (call) {
      handler.reloadPlugins();
    }, isVoid: true);

    addBotMethod("quit", (call) {
      var network = call.getArgument("network");
      var reason = call.getArgument("reason", defaultValue: "Bot Quitting");

      bot[network].client.disconnect(reason: reason);
    }, isVoid: true);

    addBotMethod("stop", (call) {
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
    }, isVoid: true);

    addBotMethod("__initialized", (call) {
      /* Plugin was initialized */
    }, isVoid: true);
  }

  void _handleRequests() {
    pm.listenAllRequest((plugin, request) {
      if (_methods.containsKey(request.command)) {
        var handler = _methods[request.command];
        var call = new Polymorphic.RemoteCall(request);
        Zone.current.fork(specification: new ZoneSpecification(handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) {
          pm.send(plugin, {
            "exception": {
              "message": "Error while calling method '${request.command}' for '${plugin}' \n\n${error}"
            }
          });
        }), zoneValues: {
          "bot.plugin.method.plugin": plugin
        }).run(() {
          try {
            handler(call);

            if (_methodInfo[request.command].isVoid) {
              call.reply(null);
            }
          } catch (e) {
            call.error("Error while calling method '${request.command}' for '${plugin}'\n\n${e}");
          }
        });
      } else {
        var call = new Polymorphic.RemoteCall(request);
        call.error("The plugin '${plugin}' tried to call the method '${request.command}', however it does not exist.");
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
      if (e.channel != null && e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("message");

      var pings = <String>["${e.client.nickname}: ", "${e.client.nickname}, "];
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

    b.client.register((IRC.CommandEvent e) {
      if (e.channel != null && e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("command");
      commonSendable(data, e);

      data['command'] = e.command;
      data['args'] = e.args;
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
      if (e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("join");
      data['channel'] = e.channel.name;
      data['user'] = e.user;
      com.pm.sendAll(data);
    });

    b.client.register((IRC.PartEvent e) {
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

    b.client.register((IRC.TopicEvent e) {
      if (e.channel.name == "#bot-communication") {
        return;
      }

      var data = common("topic");
      data['channel'] = e.channel.name;
      data['topic'] = e.topic;
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
