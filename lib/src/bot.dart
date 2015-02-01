part of polymorphic.bot;

class Bot {

  /**
   * The network name.
   */
  final String network;

  /**
   * Holds basic information to start a bot.
   */
  final serverConfig;

  /**
   * Holds the channel information the bot should auto join.
   */
  final channelConfig;

  /**
   * Holds the prefix information for the network or individual channels.
   */
  final prefixConfig;

  /**
   * The client which manages the IRC connections and data.
   */
  IRC.Client get client => _client;
  IRC.Client _client;

  /**
   * The manager handles permissions
   */
  Auth get authManager => _authManager;
  Auth _authManager;

  Bot(this.network, this.serverConfig, this.channelConfig, this.prefixConfig) {
    var botConfig = new IRC.IrcConfig();
    botConfig.nickname = serverConfig['nickname'];
    botConfig.realname = serverConfig['realname'];
    botConfig.host = serverConfig['host'];
    botConfig.port = serverConfig['port'];
    _client = new IRC.Client(botConfig);

    _registerRawHandler();
    _registerReadyHandler();
    _registerMessageHandler();
    _registerCommandHandler();
    _registerJoinPartHandlers();

    client.register((IRC.CTCPEvent event) {
      if (event.message.trim().toUpperCase() == "ARE YOU A BOT") {
        client.sendCTCP(event.user, "I AM A BOT");
      }
    });

    client.register((IRC.NickChangeEvent event) {
      if (_botMemory.containsKey(event.original)) {
        _botMemory[event.now] = _botMemory[event.original];
        _botMemory.remove(event.original);
      }
    });
    
    client.register((IRC.DisconnectEvent event) {
      Buffer.clearNetwork(network);
      print("[${network}] Disconnected");
    });
  }

  void start() {
    print("[$network] Connecting");
    client.connect();
  }

  Map<String, bool> _botMemory = {};

  void clearBotMemory() => _botMemory.clear();

  Future<bool> isUserBot(String user) {
    if (user == client.nickname) {
      return new Future.value(true);
    }

    var isBot = false;

    if (_botMemory.containsKey(user)) {
      return new Future.value(_botMemory[user]);
    }

    if (client.getChannel("#bot-communication") == null) {
      return new Future.value(false);
    } else if (!client.getChannel("#bot-communication").allUsers.contains(user)) {
      return new Future.value(false);
    }

    client.register((IRC.MessageEvent event) {
      isBot = true;
    }, filter: (IRC.MessageEvent e) => e.from != user || e.channel != "#bot-communication" || e.message != "${client.nickname}: I AM A BOT.", once: true);
    client.sendMessage("#bot-communication", "${user}: ARE YOU A BOT?");

    return new Future.delayed(new Duration(seconds: 2), () {
      _botMemory[user] = isBot;
      return isBot;
    });
  }

  void _registerRawHandler() {
    if (DEBUG) {
      client.register((IRC.LineSentEvent event) {
        print("[${network}] << ${event.line}");
      });
      
      client.register((IRC.LineReceiveEvent event) {
        print("[$network] >> ${event.line}");
      });
    }
  }

  void _registerReadyHandler() {
    client.register((IRC.ReadyEvent event) {
      if (serverConfig['owner'] != null) {
        client.identify(username: serverConfig['owner'], password: serverConfig['password'], nickserv: serverConfig['nickserv'] != null ? serverConfig['nickserv'] : "NickServ");
      }
      
      print("[$network] Bot is Ready");
      for (var chan in channelConfig) {
        event.join(chan);
      }

      if (serverConfig['broadcast'] != null && serverConfig['broadcast']) {
        event.join("#bot-communication");
      }
    });
  }
  
  void _registerJoinPartHandlers() {
    client.register((IRC.JoinEvent event) {
      if (event.channel.name == "#bot-communication") {
        return;
      }
      
      print("[${network}] <${event.channel.name}> ${event.user} joined");
    });
    
    client.register((IRC.PartEvent event) {
      if (event.channel.name == "#bot-communication") {
        return;
      }
      
      print("[${network}] <${event.channel.name}> ${event.user} left");
    });
    
    client.register((IRC.QuitPartEvent event) {
      if (event.channel.name == "#bot-communication") {
        return;
      }
      
      print("[${network}] <${event.channel.name}> ${event.user} quit");
    });
    
    client.register((IRC.BotJoinEvent event) {
      print("[${network}] Joined ${event.channel.name}");
    });
    
    client.register((IRC.BotPartEvent event) {
      print("[${network}] Left ${event.channel.name}");
    });
  }

  void _registerMessageHandler() {
    client.register((IRC.MessageEvent event) {
      if (event.isPrivate) return;
      
      BotMetrics.messagesMetric.value++;
      
      var from = event.from;
      var msg = event.message;

      if (event.channel.name == "#bot-communication") {
        if (msg.trim() == "${client.nickname}: ARE YOU A BOT") {
          event.reply("${event.from}: I AM A BOT");
        } else if (msg.trim().endsWith(": I AM A BOT")) {
          var nick = msg.split(":")[0].trim();
          if (_botMemory[nick] != true) {
            _botMemory[nick] = true;
            Globals.pluginHandler.pm.sendAll({
              "type": "event",
              "event": "bot-detected",
              "network": network,
              "user": nick
            });
          }
        } else if (msg.trim() == "FIND BOTS") {
          event.reply("${event.from}: I AM A BOT");
        } else if (msg.trim() == "PREFIXES") {
          event.reply("MY PREFIX FOR ${event.channel.name} IS ${getPrefix(event.channel.name)}");
        } else if (msg.trim().startsWith("${client.nickname}: WHAT IS YOUR PREFIX FOR ")) {
          var channel = msg.trim().substring("${client.nickname}: WHAT IS YOUR PREFIX FOR ".length);
          event.reply("${event.from}: MY PREFIX FOR ${channel} IS ${getPrefix(channel)}");
        } else if (msg.trim() == "${client.nickname}: WHAT EXTENSIONS DO YOU SUPPORT") {
          event.reply("${event.from}: I SUPPORT " + Globals.EXTENSIONS.join(" "));
        } else if (msg.trim() == "${client.nickname}: WHAT POLYMORPHIC PLUGINS DO YOU HAVE") {
          event.reply("${event.from}: I HAVE THE POLYMORPHIC PLUGINS ${Globals.pluginHandler.pm.plugins.join(" ")}");
        }
        return;
      }

      var cleanMsg = Polymorphic.DisplayHelpers.clean(msg);
      
      if (event.isPrivate) {
        print("[$network] <$from> ${cleanMsg}");
      } else {
        print("[$network] <${event.channel.name}><$from> ${cleanMsg}");
      }
      
      String prefix;
      if (!event.isPrivate) prefix = prefixConfig[event.channel.name];
      if (prefix == null) prefix = prefixConfig['default'];
      if (prefix == null) throw new Exception("[$network] No Prefix Set");
      if (event.message.startsWith(prefix)) {
        List<String> args = event.message.split(' ');
        String command = args[0].substring(1);
        args.removeAt(0);
        client.post(new IRC.CommandEvent(event, command, args));
      }
      
      new Future.delayed(new Duration(milliseconds: 500), () {
        Buffer.handle(network, event);
      });
    });
  }

  String getPrefix(String channel) {
    if (prefixConfig[channel] != null) {
      return prefixConfig[channel];
    } else {
      return prefixConfig["default"];
    }
  }

  void _registerCommandHandler() {
    _authManager = new Auth(network, this);

    client.register((IRC.CommandEvent event) {
      if (event.channel.name == "#bot-communication") {
        return;
      }

      String node = "auth";
      _authManager.hasPermission("core", event.from, node).then((bool has) {
        if (!has) {
          event.reply("${event.from}> You are not authorized to perform this action (missing core.$node)");
          return;
        }

        if (event.args.length == 0) {
          _authManager.registeredAs(event.from).then((List<String> s) {
            if (s[0] == null) {
              event.reply("> ${s[1]}");
            } else {
              event.reply("> You are authenticated as ${s[0]}");
            }
          });
        } else if (event.args.length == 1) {
          if (!event.isPrivate && event.args[0] == "force") {
            _authManager.registeredAs(event.from).then((List<String> s) {
              if (s[0] == null) {
                event.reply("> Forcing an authentication lookup");
                _authManager.authenticate(event.from);
              } else {
                event.reply("> ${Auth.LOGGED}");
              }
            });
          }
        }
      });
    }, filter: (IRC.CommandEvent e) => e.command != "auth");

    client.register((IRC.CommandEvent event) {
      if (event.channel.name == "#bot-communication") {
        return;
      }

      String node = "enable";

      _authManager.hasPermission("core", event.from, node).then((bool has) {
        if (!has) {
          event.reply("${event.from}> You are not authorized to perform this action (missing core.$node)");
          return;
        }

        if (event.args.length != 1) {
          event.reply("> Usage: enable <plugin>");
          return;
        }

        if (!Globals.pluginHandler._candidates.contains(event.args[0])) {
          event.reply("> ${event.args[0]} is not a valid plugin.");
          return;
        }

        if (!Globals.pluginHandler._disabled.contains(event.args[0])) {
          event.reply("> ${event.args[0]} is not disabled.");
          return;
        }

        Globals.pluginHandler.enable(event.args[0]).then((_) {
          event.reply("> ${event.args[0]} is now enabled.");
        }).catchError((e) {
          if (e is PluginDependencyException) {
            var plugin = e.plugin;
            var deps = e.dependencies;

            event.reply("Failed to enable ${plugin}: ${deps.map((it) => "'${it}'").join(", ")} ${deps.length > 1 ? "" : "depends"} ${deps.length > 1 ? "are" : "is"} required, but ${deps.length > 1 ? "they are" : "it is"} not enabled.");
            return;
          } else {
            throw e;
          }
        });
        ;
      });
    }, filter: (IRC.CommandEvent e) => e.command != "enable");

    client.register((IRC.CommandEvent event) {
      if (event.channel.name == "#bot-communication") {
        return;
      }

      String node = "disable";

      _authManager.hasPermission("core", event.from, node).then((bool has) {
        if (!has) {
          event.reply("${event.from}> You are not authorized to perform this action (missing core.$node)");
          return;
        }

        if (event.args.length != 1) {
          event.reply("> Usage: disable <plugin>");
          return;
        }

        if (!Globals.pluginHandler._candidates.contains(event.args[0])) {
          event.reply("> ${event.args[0]} is not a valid plugin.");
          return;
        }

        if (Globals.pluginHandler._disabled.contains(event.args[0])) {
          event.reply("> ${event.args[0]} is not enabled.");
          return;
        }

        Globals.pluginHandler.disable(event.args[0]).then((_) {
          event.reply("> ${event.args[0]} is now disabled.");
        }).catchError((e) {
          if (e is PluginDependencyException) {
            var plugin = e.plugin;
            var deps = e.dependencies;

            event.reply("Failed to disable ${plugin}: ${deps.map((it) => "'${it}'").join(", ")} ${deps.length > 1 ? "all depend" : "depends"} on it, but ${deps.length > 1 ? "are" : "is"} not disabled.");
            return;
          } else {
            throw e;
          }
        });
      });
    }, filter: (IRC.CommandEvent e) => e.command != "disable");

    client.register((IRC.CommandEvent event) {
      if (event.channel.name == "#bot-communication") {
        return;
      }

      String node = "reload";

      _authManager.hasPermission("core", event.from, node).then((bool has) {
        if (!has) {
          event.reply("${event.from}> You are not authorized to perform this action (missing core.$node)");
          return;
        }

        if (event.args.isNotEmpty) {
          event.reply("[${IRC.Color.BLUE}Polymorphic${IRC.Color.RESET}] Usage: reload");
          return;
        }

        event.reply("[${IRC.Color.BLUE}Polymorphic${IRC.Color.RESET}] Reloading Plugins...");
        Globals.pluginHandler.reloadPlugins().then((_) {
          event.reply("[${IRC.Color.BLUE}Polymorphic${IRC.Color.RESET}] Plugins have been reloaded.");
        });
      });
    }, filter: (e) => e.command != "reload");
  }
  
  void destroy() {
    if (client != null) {
      client.disconnect();
    }
  }
}

class BufferEntry {
  final String network;
  final String target;
  final String user;
  final String message;

  BufferEntry(this.network, this.target, this.user, this.message);

  factory BufferEntry.fromData(Map data) {
    String network = data['network'];
    String target = data['target'];
    String message = data['message'];
    String user = data['from'];

    return new BufferEntry(network, target, user, message);
  }
  
  Map toData() => {
    "network": network,
    "target": target,
    "from": user,
    "message": message
  };
}

class Buffer {
  static Map<String, Buffer> buffers = new Map<String, Buffer>();

  List<BufferEntry> messages = [];
  final int _limit = 30;
  int _tracker = 0;

  void _handle(BufferEntry entry) {
    if (entry.message.startsWith("s/")) return;

    if (_tracker > _limit - 1) _tracker = 0;
    messages[_tracker] = entry;
    _tracker++;
  }

  static void handle(String network, IRC.MessageEvent event) {
    String target = event.target;
    String message = event.message;
    String user = event.from;

    var buf = buffers["${network}${target}"];

    if (buf == null) {
      buf = new Buffer();
      buffers["${network}${target}"] = buf;
      for (int i = 0; i < 30; i++) buf.messages.add(null);
    }

    buf._handle(new BufferEntry(network, target, user, message));
  }

  static List<BufferEntry> get(String name) {
    var buf = buffers[name];
    if (buf == null) return <BufferEntry>[];

    var list = buf.messages;
    var tracker = buf._tracker;

    List<BufferEntry> newList = [];

    for (int i = buf._tracker - 1; i >= 0; i--) {
      if (list[i] == null) break;
      newList.add(list[i]);
    }

    for (int i = buf._limit - 1; i >= buf._tracker; i--) {
      if (list[i] == null) break;
      newList.add(list[i]);
    }

    return newList;
  }

  static void clear(String name) {
    var buf = buffers[name];
    if (buf != null) buf.messages.clear();
  }
  
  static void clearNetwork(String name) {
    for (var k in buffers.keys.where((it) => it.startsWith("${name}#"))) {
      clear(k);
    }
  }
}