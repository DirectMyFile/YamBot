part of polymorphic.bot;

class Bot {

  /**
   * The network name.
   */
  final String server;

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
   * Holds all the permission nodes the user has permission to.
   */
  final permsConfig;

  /**
   * Holds all the permission nodes for each group.
   */
  final groupsConfig;

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

  Bot(this.server, this.serverConfig,
      this.channelConfig, this.prefixConfig,
      this.permsConfig, this.groupsConfig) {
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
  }

  void start() {
    print("[$server] Connecting");
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
    
    client.register((IRC.CTCPEvent event) {
      isBot = event.message.trim().toUpperCase() == "I AM A BOT";
    }, filter: (IRC.CTCPEvent event) => event.user != user && event.target != client.nickname, once: true);
    client.sendCTCP(user, "ARE YOU A BOT");
    
    return new Future.delayed(new Duration(seconds: 2), () {
      _botMemory[user] = isBot;
      return isBot;
    });
  }

  void _registerRawHandler() {
    void _rawHandler(IRC.LineReceiveEvent event) {
      print("[$server] ${event.line}");
    }
    client.register(_rawHandler);
    client.register((IRC.ReadyEvent event) {
      new Future.delayed(new Duration(milliseconds: 20), () {
        client.unregister(_rawHandler);
      });
    });
  }

  void _registerReadyHandler() {
    client.register((IRC.ReadyEvent event) {
      if (serverConfig['owner'] != null) {
        client.identify(username: serverConfig['owner'],
                        password: serverConfig['password'], nickserv: serverConfig['nickserv'] != null ? serverConfig['nickserv'] : "NickServ");
      }
      print("[$server] Bot is Ready");
      for (var chan in channelConfig) {
        print("[$server] Joining $chan");
        event.join(chan);
      }
    });
  }

  void _registerMessageHandler() {
    client.register((IRC.MessageEvent event) {
      var from = event.from;
      var msg = event.message;
      if (event.isPrivate) {
        print("[$server] <$from> $msg");
      } else {
        print("[$server] <${event.channel.name}><$from> $msg");
      }

      String prefix;
      if (!event.isPrivate)
        prefix = prefixConfig[event.channel.name];
      if (prefix == null)
        prefix = prefixConfig['default'];
      if (prefix == null)
        throw new Exception("[$server] No prefix set");
      if (event.message.startsWith(prefix)) {
        List<String> args = event.message.split(' ');
        String command = args[0].substring(1);
        args.removeAt(0);
        client.post(new IRC.CommandEvent(event, command, args));
      }
    });
  }

  void _registerCommandHandler() {
    _authManager = new Auth(server, this);

    client.register((IRC.CommandEvent event) {
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
          event.reply("> '${event.args[0]}' is not a valid plugin.");
          return;
        }
        
        if (!Globals.pluginHandler._disabled.contains(event.args[0])) {
          event.reply("> '${event.args[0]}' is not disabled.");
          return;
        }
        
        Globals.pluginHandler.enable(event.args[0]).then((_) {
          event.reply("> '${event.args[0]}' is now enabled.");
        });
      });
    }, filter: (IRC.CommandEvent e) => e.command != "enable");
    
    client.register((IRC.CommandEvent event) {
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
          event.reply("> '${event.args[0]}' is not a valid plugin.");
          return;
        }
        
        if (Globals.pluginHandler._disabled.contains(event.args[0])) {
          event.reply("> '${event.args[0]}' is not enabled.");
          return;
        }
        
        Globals.pluginHandler.enable(event.args[0]).then((_) {
          event.reply("> '${event.args[0]}' is now disabled.");
        });
      });
    }, filter: (IRC.CommandEvent e) => e.command != "disable");
  }
}
