part of yambot;

class Auth {

  /**
   * The auth system this is good for
   */
  final IRC.Client client;

  /**
   * The network this auth system is connected to.
   */
  final String network;

  final Queue<String> _queue = new Queue<String>();
  final RegExp _regex = new RegExp(r"(\u0002)([^\u0002]+)\1");

  final Map<String, String> _authenticated = {};

  // Nicks that are not logged in will be placed here
  final List<String> _rejected = [];

  Completer _completer;

  Auth(this.network, this.client) {
    client.register((IRC.WhoisEvent e) {
      _process(e);
    });

    client.register((IRC.PartEvent e) {
      _authenticated.remove(e.user);
    });

    client.register((IRC.NickChangeEvent e) {
      if (_authenticated.containsKey(e.original)) {
        var ns = _authenticated.remove(e.original);
        _authenticated.putIfAbsent(e.now, () => ns);
      }
    });
  }

  /**
   * Element 0 of [List] is the registered username of the [nick] or null if
   * not logged in. Element 1 of [List] is an error reason.
   */
  Future<List<String>> registeredAs(String nick) {
    if (_authenticated.containsKey(nick)) {
      return new Future.sync(() => _authenticated[nick]);
    } else if (_rejected.contains(nick)) {
      return new Future.sync(() => null);
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
   * The [account] is the nickserv registered name to perform a lookup
   * on.
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
    client.send("WHOIS ${_queue.first}");
  }

  void _process(IRC.WhoisEvent event) {
    if (event.username != null) {
      bool success = false;
      for (var c in client.channels) {
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
        _done(null, "You must be in at least 1 channel that the bot is in to authenticate.");
      }
    } else {
      _rejected.add(event.nickname);
      _done(null, "You are not logged into NickServ");
    }
  }

  void _done(String data, [String reason]) {
    if (_completer != null) _completer.complete([data, reason]);
    _completer = null;
    _queue.removeFirst();
    if (_queue.length > 0) _authenticate();
  }
}
