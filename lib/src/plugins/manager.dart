part of yambot;

class PluginHandler {

  final PluginManager pm = new PluginManager();
  final YamBot bot;

  PluginHandler(this.bot);

  Future init() {
    return load().then((List<Plugin> plugins) {
      print("Plugins registered: ${plugins.join(" ")}");
      pm.listenAll((String plugin, Map _data) {
        var m = new VerificationManager(plugin, _data);
        Bot b = bot[m['network']];
        var c = m['command'];
        if (c != null) m.type = c;
        switch (c) {
          case "message":
            String msg = m['message'];
            String target = m['target'];
            b.client.message(target, msg);
            break;
          default:
            throw new Exception("$plugin sent an invalid command: $c");
        }
      });
      return plugins;
    });
  }

  void initListeners() {
    bot.bots.forEach((String network) {
      Bot b = bot[network];
      b.client.register((IRC.MessageEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "message";
        data['target'] = e.target;
        data['from'] = e.from;
        data['private'] = e.isPrivate;
        data['message'] = e.message;
        pm.sendAll(data);
      });

      b.client.register((IRC.CommandEvent e) {
        var data = {};
        data['network'] = network;
        data['event'] = "command";
        data['target'] = e.target;
        data['from'] = e.from;
        data['private'] = e.isPrivate;
        data['message'] = e.message;

        data['command'] = e.command;
        data['args'] = e.args;
        pm.sendAll(data);
      });
    });
  }

  Future load() {
    Directory dir = new Directory("plugins");
    if (!dir.existsSync()) dir.createSync();
    return pm.loadAll(dir);
  }
}

class VerificationManager {

  final String plugin;
  final Map data;

  /**
   * The type of command to execute, if any
   */
  String type;

  VerificationManager(this.plugin, this.data);

  dynamic operator[](String field) {
    return verify(field);
  }

  dynamic verify(String field) {
    var info = data[field];
    if (info == null) {
      if (type != null) {
        throw new Exception("$plugin is missing field '$field' when sending command '$type'");
      } else {
        throw new Exception("$plugin is missing field '$field'");
      }
    }
    return info;
  }
}
