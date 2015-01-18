part of polymorphic.api;

typedef void RemoteCallHandler(RemoteCall call);

class RemoteCall {
  final Request request;

  RemoteCall(this.request);

  dynamic getArgument(String name, {dynamic defaultValue}) {
    if (request.data == null || (!request.data.containsKey(name) && request.data["value"] is! Map)) {
      return defaultValue;
    }
    
    if (request.data.containsKey(name)) {
      return request.data[name];
    } else {
      return request.data["value"].containsKey(name) ? request.data["value"][name] : defaultValue;
    }
  }

  void reply(dynamic value) => request.reply({
    "value": value
  });
  
  void error(String message) => request.reply({
    "exception": {
      "message": message
    }
  });
}

class RemoteMethodInfo {
  final String name;
  final bool isVoid;
  final Map<String, dynamic> metadata;

  RemoteMethodInfo(this.name, {this.metadata: const {}, this.isVoid: false});
}

class PluginInterface {
  final Plugin myPlugin;
  final String pluginName;

  PluginInterface(this.myPlugin, this.pluginName);

  Future callMethod(String method, [dynamic arguments]) {
    return myPlugin.callRemoteMethod(pluginName, method, arguments);
  }

  Future<List<RemoteMethodInfo>> listMethods() {
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
      if (!_ctcpController.isClosed) {
        _ctcpController.add(event.message);
      }
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

  void destroy() {
    _ctcpController.close();
  }
}

class PrefixNegotiation {
  final BotConnector bot;
  final String mine;
  final String theirs;

  PrefixNegotiation(this.bot, this.mine, this.theirs);
}