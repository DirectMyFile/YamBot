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

  // Current account that is being authenticated
  String _account;
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
   * [String] is null if not logged in. Otherwise it retrieves the account
   * the [nick] is logged in as.
   */
  Future<String> registeredAs(String nick) {
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
    if (_account != null) {
      throw new Exception("Authentication already in process");
    }
    _account = _queue.first;
    client.send("WHOIS $_account");
  }

  void _process(IRC.WhoisEvent event) {
    if (event.username != null) {
      _authenticated.putIfAbsent(event.nickname, () => event.username);
      _rejected.remove(event.nickname);
    } else {
      _rejected.add(event.nickname);
    }
    _done(event.username);
  }

  void _done(String data) {
    if (_completer != null) _completer.complete(data);
    _account = null;
    _completer = null;
    _queue.removeFirst();
    if (_queue.length > 0) _authenticate();
  }
}
