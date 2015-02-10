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
    bot.setChannelTopic(network, name, topic);
    refresh();
  }
  
  bool isInChannel = true;

  Channel(this.bot, this.network, this.name, this._topic, this.members, this.ops, this.voices, this.halfOps, this.owners);

  Future refresh() {
    return renew().then((channel) {
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
  
  Future<Channel> renew() => bot.getChannel(network, name);

  void op(String user) {
    bot.op(network, name, user);
  }
  
  void deop(String user) {
    bot.deop(network, name, user);
  }
  
  void voice(String user) {
    bot.voice(network, name, user);
  }
  
  void devoice(String user) {
    bot.devoice(network, name, user);
  }
  
  void mode(String mode, {String user}) {
    bot.mode(network, mode, channel: name, user: user);
  }
  
  void owner(String user) {
    bot.owner(network, name, user);
  }
  
  void deowner(String user) {
    bot.deowner(network, name, user);
  }
  
  void halfOp(String user) {
    bot.halfOp(network, name, user);
  }
  
  void dehalfOp(String user) {
    bot.dehalfOp(network, name, user);
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