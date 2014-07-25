part of polymorphic.bot;

class Auth {

  static const String LOGGED = "You are already logged into NickServ";
  static const String UNLOGGED = "You are not logged into NickServ";
  static const String CHANNEL =
      "You must be in at least 1 channel that the bot is in to authenticate.";

  /**
   * The auth system this is good for
   */
  final Bot bot;

  /**
   * The network this auth system is connected to.
   */
  final String network;

  final RegExp _regex = new RegExp(r"(\u0002)([^\u0002]+)\1");
  final Queue<String> _queue = new Queue<String>();

  final Map<String, String> _authenticated = {};
  final List<String> _rejected = [];

  Completer _completer;

  Auth(this.network, this.bot) {
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
    return registeredAs(nick).then((List<String> info) {
      var nickserv = info[0];
      if (nickserv == null) return false;

      var node_parts = node.split(".");

      var success = userHasMatch(nickserv, plugin, node_parts);
      if (success == null) {
        success = userHasMatch("*", plugin, node_parts);
      }
      return success != null ? success : false;
    });
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
   * Deauthenticates the [nickname] if authenticated.
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

  bool userHasMatch(String user, String plugin, node_parts) {
    var success;
    var perms = bot.permsConfig[user];
    for (var perm in (perms == null ? [] : perms)) {
      var perm_parts = perm.split(".");
      if (hasMatch("-" + plugin, perm_parts, node_parts)) {
        return false;
      } else if (hasMatch(plugin, perm_parts, node_parts)) {
        success = true;
      }
    }
    return success;
  }

  bool hasMatch(String plugin, perm_parts, node_parts) {
    if (perm_parts[0] != plugin) return false;
    var success = false;

    perm_parts.removeAt(0);
    for (int i = 0; i < perm_parts.length; i++) {
      if (i > node_parts.length) break;
      if (perm_parts[i] == "*") {
        return true;
      } else if (node_parts[i] == perm_parts[i]) {
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
        var voice = event.voice_in;
        var op = event.op_in;
        if (regular.contains(c.name)
            || voice.contains(c.name)
            || op.contains(c.name)) {
          _authenticated.putIfAbsent(event.nickname, () => event.username);
          _rejected.remove(event.nickname);
          _done(event.username);
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
    _completer = null;
    _queue.removeFirst();
    if (_queue.length > 0) _authenticate();
  }
}
