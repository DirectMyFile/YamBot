part of polymorphic.bot;

const String DEFAULT_PERMS = """
groups:
  public:
    - core.auth
networks:
  EsperNet:
    groups:
      "*":
      - public
    nodes:
      "*": []
""";

class Auth {
  static const String LOGGED = "You are already logged into NickServ";
  static const String UNLOGGED = "You are not logged into NickServ";
  static const String CHANNEL = "You must be in at least 1 channel that the bot is in to authenticate.";
  
  /**
   * The auth system this is good for
   */
  final Bot bot;

  /**
   * The network this auth system is connected to.
   */
  final String network;
  final Queue<String> _queue = new Queue<String>();

  final Map<String, String> _authenticated = {};
  final List<String> _rejected = [];
  final File file = new File("permissions.yaml");
  Map p;

  Completer _completer;

  Auth(this.network, this.bot) {
    var jsonFile = new File("permissions.json");
    
    if (!file.existsSync() && jsonFile.existsSync()) {
      file.writeAsStringSync(encodeYAML(JSON.decode(jsonFile.readAsStringSync())));
      jsonFile.deleteSync();
    }
    
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync(DEFAULT_PERMS);
    }

    void fillIn() {
      if (!p.containsKey("groups")) {
        p["groups"] = {};
      }

      if (!p.containsKey("networks")) {
        p["networks"] = {};
      }

      if (!p["networks"].containsKey(bot.network)) {
        p["networks"][bot.network] = {
          "nodes": {},
          "groups": {}
        };
      }

      if (!p["networks"][bot.network].containsKey("nodes")) {
        p["networks"][bot.network]["nodes"] = {};
      }

      if (!p["networks"][bot.network].containsKey("groups")) {
        p["networks"][bot.network]["groups"] = {};
      }
    }

    p = new Map<dynamic, dynamic>.from(yaml.loadYaml(file.readAsStringSync()));
    fillIn();

    file.watch(events: FileSystemEvent.MODIFY).listen((e) {
      print("[Auth] Reloading Permissions");
      try {
        p = yaml.loadYaml(file.readAsStringSync());
      } on FormatException catch (e) {
        print("[Auth] Permissions file is corrupt:");
        print(e);
        return;
      }
      fillIn();
    });

    bot.client.register((IRC.WhoisEvent e) {
      _process(e);
    });

    bot.client.register((IRC.KickEvent e) {
      _authenticated.remove(e.user);
    });

    bot.client.register((IRC.PartEvent e) {
      _authenticated.remove(e.user);
    });

    bot.client.register((IRC.NickChangeEvent e) {
      if (_authenticated.containsKey(e.original)) {
        var ns = _authenticated.remove(e.original);
        _authenticated.putIfAbsent(e.now, () => ns);
      }
    });
  }

  Future<bool> hasPermission(String plugin, String nick, String node) {
    if (bot.isSlackBot) {
      return new Future.sync(() {
        var parts = node.split(".");
        var success = _userHasMatch(nick, plugin, parts);

        if (success == null) {
          success = _userHasMatch("*", plugin, parts);
        }
        
        if (success == null) {
          success = _userHasMatch(nick, "*", parts);
        }
        
        if (success == null) {
          success = _userHasMatch("*", "*", parts);
        }

        return success != null ? success : false;
      });
    } else {
      return registeredAs(nick).then((List<String> info) {
        var nickserv = info[0];
        if (nickserv == null) return false;

        var parts = node.split(".");

        var success = _userHasMatch(nickserv, plugin, parts);
        
        if (success == null) {
          success = _userHasMatch("*", plugin, parts);
        }
        
        if (success == null) {
          success = _userHasMatch(nick, "*", parts);
        }
        
        if (success == null) {
          success = _userHasMatch("*", "*", parts);
        }
        
        return success != null ? success : false;
      });
    }
  }

  /**
   * Element 0 of [List] is the registered username of the [nick] or null if
   * not logged in. Element 1 of [List] is an error reason.
   */
  Future<List<String>> registeredAs(String nick) {
    if (_authenticated.containsKey(nick)) {
      return new Future.sync(() => [_authenticated[nick]]);
    } else if (_rejected.contains(nick)) {
      return new Future.sync(() => [null, UNLOGGED]);
    } else {
      _completer = new Completer();
      authenticate(nick);
      return _completer.future;
    }
  }

  /**
   * De-authenticates the [nickname] if authenticated.
   */
  void deauthenticate(String nickname) {
    _authenticated.remove(nickname);
  }

  /**
   * The [account] is the nickserv registered name to perform a lookup on.
   */
  void authenticate(String account) {
    if (_queue.length > 0) {
      _queue.add(account);
    } else {
      _queue.add(account);
      _authenticate();
    }
  }

  /**
   * Handles the queue one account at a time.
   */
  void _authenticate() {
    bot.client.send("WHOIS ${_queue.first}");
  }

  bool _userHasMatch(String user, String plugin, nodeParts) {
    var success;

    var groups = p['networks'][bot.network]['groups'][user];
    var perms = p['networks'][bot.network]['nodes'][user];

    for (var perm in (perms == null ? [] : perms)) {
      var permParts = perm.split(".");
      if (_hasMatch("-" + plugin, permParts, nodeParts)) {
        success = false;
      } else if (_hasMatch(plugin, permParts, nodeParts)) {
        return true;
      }
    }

    // No need to check groups if already successful
    if (success != null && success) return true;

    for (var group in (groups == null ? [] : groups)) {
      var groupPerms = p["groups"][group];
      if (groupPerms == null) continue;

      for (var perm in groupPerms) {
        var permParts = perm.split(".");

        if (_hasMatch("-" + plugin, permParts, nodeParts)) {
          success = false;
        } else if (_hasMatch(plugin, permParts, nodeParts)) {
          return true;
        }
      }
    }

    return success;
  }

  bool _hasMatch(String plugin, permParts, nodeParts) {
    if (permParts.length == 1 && permParts[0] == "*") return true;

    if (permParts[0] != plugin) return false;
    var success = false;

    permParts.removeAt(0);
    for (int i = 0; i < permParts.length; i++) {
      if (permParts[i] == "*") {
        success = true;
      } else if (nodeParts[i] == permParts[i]) {
        success = true;
      } else {
        success = false;
        break;
      }
    }

    return success;
  }

  void _process(IRC.WhoisEvent event) {
    if (event.username != null) {
      bool success = false;
      for (var c in bot.client.channels) {
        var regular = event.member_in;
        var voice = event.voicedChannels;
        var op = event.operatorChannels;
        if (regular.contains(c.name) || voice.contains(c.name) || op.contains(c.name)) {
          _authenticated.putIfAbsent(event.nickname, () => event.username);
          _rejected.remove(event.nickname);
          _done(event.username);
          success = true;
          break;
        }
      }
      if (!success) {
        _done(null, CHANNEL);
      }
    } else {
      _rejected.add(event.nickname);
      _done(null, UNLOGGED);
    }
  }

  void _done(String data, [String reason]) {
    if (_completer != null) _completer.complete([data, reason]);
    if (_queue.length > 0) _queue.removeFirst();
    if (_queue.length > 0) _authenticate();
  }
}
