part of polymorphic.api;

typedef void CommandHandler(CommandEvent event);
typedef void MessageHandler(MessageEvent event);
typedef void JoinHandler(JoinEvent event);
typedef void PartHandler(PartEvent event);
typedef void BotJoinHandler(BotJoinEvent event);
typedef void BotPartHandler(BotPartEvent event);

typedef void ShutdownAction();

class MessageEvent {
  final BotConnector bot;
  final String network;
  final String target;
  final String from;
  final bool isPrivate;
  final String message;
  
  MessageEvent(this.bot, this.network, this.target, this.from, this.isPrivate, this.message);
  
  void reply(String msg) {
    bot.sendMessage(network, target, msg);
  }
}

class JoinEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  final String user;
  
  JoinEvent(this.bot, this.network, this.channel, this.user);
}

class PartEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  final String user;
  
  PartEvent(this.bot, this.network, this.channel, this.user);
}

class BotJoinEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  
  BotJoinEvent(this.bot, this.network, this.channel);
}

class BotPartEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  
  BotPartEvent(this.bot, this.network, this.channel);
}