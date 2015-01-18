part of polymorphic.api;

class Command {
  final String name;
  final String permission;
  
  const Command(this.name, {this.permission});
}

class EventHandler {
  final String event;
  
  const EventHandler(this.event);
}

class OnJoin {
  final String network;
  final String user;
  final String channel;
  
  const OnJoin({this.network, this.user, this.channel});
}

class OnPart {
  final String network;
  final String user;
  final String channel;
  
  const OnPart({this.network, this.user, this.channel});
}

class RemoteMethod {
  final String name;
  final bool isVoid;
  
  const RemoteMethod({this.name, this.isVoid});
}

class OnBotJoin {
  final String network;
  final String channel;
  
  const OnBotJoin({this.network, this.channel});
}

class OnBotPart {
  final String network;
  final String channel;
  
  const OnBotPart({this.network, this.channel});
}

class OnMessage {
  final Pattern pattern;
  
  const OnMessage({this.pattern});
}

class BotInstance {
  const BotInstance();
}

class PluginInstance {
  const PluginInstance();
}