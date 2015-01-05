part of polymorphic.api;

typedef void RemoteCallHandler(RemoteCall call);

class RemoteCall {
  final Request request;

  RemoteCall(this.request);

  dynamic getArgument(String name, {dynamic defaultValue}) => request.data.containsKey(name) ? request.data[name] : defaultValue;

  void reply(dynamic value) => request.reply({
    "value": value
  });

  void replyMap(Map<String, dynamic> map) => request.reply(map);
}

class RemoteMethod {
  final String name;
  final bool isVoid;
  final Map<String, dynamic> metadata;

  RemoteMethod(this.name, {this.metadata: const {}, this.isVoid: false});
}

class PluginInterface {
  final Plugin myPlugin;
  final String pluginName;

  PluginInterface(this.myPlugin, this.pluginName);

  Future callMethod(String method, [dynamic arguments]) {
    return myPlugin.callRemoteMethod(pluginName, method, arguments);
  }

  Future<List<RemoteMethod>> listMethods() {
    return myPlugin.getRemoteMethods(pluginName);
  }
}

class BotInterface {
  final BotConnector bot;
  final String network;
  final String user;

  StreamController<String> _ctcpController = new StreamController<String>.broadcast();
  Stream<String> get _ctcp => _ctcpController.stream;

  BotInterface(this.bot, this.network, this.user) {
    bot.onCTCP((CTCPEvent event) {
      _ctcpController.add(event.message);
    }, network: network, user: user);
  }

  Future<PrefixNegotiation> negotiatePrefix(String channel) {
    var completer = new Completer();

    String mine;
    _ctcp.single.then((msg) {
      if (msg.startsWith("MY PREFIX FOR ${channel} IS ")) {
        completer.complete(new PrefixNegotiation(bot, mine, msg.substring("MY PREFIX FOR ${channel} IS ".length)));
      }
    });

    bot.getPrefix(network, channel).then((prefix) {
      mine = prefix;
      bot.sendCTCP(network, user, "MY PREFIX FOR ${channel} IS ${prefix}");
    });

    return completer.future;
  }
}

class PrefixNegotiation {
  final BotConnector bot;
  final String mine;
  final String theirs;

  PrefixNegotiation(this.bot, this.mine, this.theirs);
}