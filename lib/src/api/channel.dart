part of polymorphic.api;

class Channel {
  final BotConnector bot;
  final String network;
  final String name;
  final List<String> members;
  final List<String> ops;
  final List<String> voices;
  final List<String> halfOps;
  final List<String> owners;
  
  String _topic;
  
  String get topic => _topic;
  set topic(String value) {
    bot.sendRawLine(network, "TOPIC ${name} :${value}");
    refresh();
  }
  
  bool isInChannel = true;

  Channel(this.bot, this.network, this.name, this._topic, this.members, this.ops, this.voices, this.halfOps, this.owners);

  Future refresh() {
    return bot.getChannel(network, name).then((channel) {
      if (channel == null) {
        isInChannel = false;
        return;
      }

      _topic = channel.topic;
      members.clear();
      members.addAll(channel.members);
      voices.clear();
      voices.addAll(channel.voices);
      ops.clear();
      ops.addAll(channel.ops);
      halfOps.clear();
      halfOps.addAll(channel.halfOps);
      owners.clear();
      owners.addAll(channel.owners);
    });
  }

  void sendMessage(String msg) {
    bot.sendMessage(network, name, msg);
  }

  void sendNotice(String msg) {
    bot.sendNotice(network, name, msg);
  }

  void sendAction(String msg) {
    bot.sendAction(network, name, msg);
  }

  void sendCTCP(String msg) {
    bot.sendCTCP(network, name, msg);
  }
}