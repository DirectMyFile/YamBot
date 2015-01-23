part of polymorphic.api;

typedef void CommandHandler(CommandEvent event);
typedef void MessageHandler(MessageEvent event);
typedef void JoinHandler(JoinEvent event);
typedef void PartHandler(PartEvent event);
typedef void BotJoinHandler(BotJoinEvent event);
typedef void BotPartHandler(BotPartEvent event);
typedef void CTCPHandler(CTCPEvent event);
typedef void ReadyHandler(ReadyEvent event);
typedef void NoticeHandler(NoticeEvent event);
typedef void InviteHandler(InviteEvent event);
typedef void ConnectHandler(ConnectEvent event);
typedef void DisconnectHandler(DisconnectEvent event);
typedef void TopicHandler(TopicEvent event);
typedef void ModeHandler(ModeEvent event);
typedef void BotDetectionHandler(BotDetectionEvent event);
typedef void ActionHandler(ActionEvent event);
typedef void QuitHandler(QuitEvent event);
typedef void QuitPartHandler(QuitPartEvent event);

typedef void ShutdownAction();

class ConnectEvent {
  final BotConnector bot;
  final String network;

  ConnectEvent(this.bot, this.network);
}

class QuitEvent {
  final BotConnector bot;
  final String network;
  final String user;
  
  QuitEvent(this.bot, this.network, this.user);
}

class QuitPartEvent {
  final BotConnector bot;
  final String network;
  final String user;
  final String channel;
  
  QuitPartEvent(this.bot, this.network, this.channel, this.user);
}

class ActionEvent {
  final BotConnector bot;
  final String network;
  final String target;
  final String user;
  final String message;

  ActionEvent(this.bot, this.network, this.target, this.user, this.message);

  void reply(String msg) {
    bot.sendAction(network, target, msg);
  }
}

class ModeEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  final String user;
  final String mode;

  ModeEvent(this.bot, this.network, this.channel, this.user, this.mode);
}

class TopicEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  final String topic;

  TopicEvent(this.bot, this.network, this.channel, this.topic);
}

class DisconnectEvent {
  final BotConnector bot;
  final String network;

  DisconnectEvent(this.bot, this.network);
}

class ReadyEvent {
  final BotConnector bot;
  final String network;

  ReadyEvent(this.bot, this.network);
}

class InviteEvent {
  final BotConnector bot;
  final String network;
  final String user;
  final String channel;

  InviteEvent(this.bot, this.network, this.user, this.channel);
}

class NoticeEvent {
  final BotConnector bot;
  final String network;
  final String target;
  final String from;
  final bool isPrivate;
  final String message;

  NoticeEvent(this.bot, this.network, this.target, this.from, this.isPrivate, this.message);

  void reply(String msg) {
    bot.sendNotice(network, isPrivate ? from : target, msg);
  }
}

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
  
  void kickUser({String reason}) {
    bot.kick(network, target, from, reason: reason);
  }
  
  void ban() {
    bot.ban(network, target, from);
  }
  
  void kickBanUser({String reason}) {
    bot.kickBan(network, target, from, reason: reason);
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

class CTCPEvent {
  final BotConnector bot;
  final String network;
  final String target;
  final String user;
  final String message;

  CTCPEvent(this.bot, this.network, this.target, this.user, this.message);

  void reply(String msg) {
    bot.sendCTCP(network, target, msg);
  }
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

class BotDetectionEvent {
  final BotConnector bot;
  final String network;
  final String user;

  BotDetectionEvent(this.bot, this.network, this.user);
}

class UserInfo {
  final BotConnector bot;
  final String network;
  final String nickname;
  final String username;
  final String realname;
  final bool isAway;
  final String awayMessage;
  final bool isServerOperator;
  final String hostname;
  final bool isIdle;
  final int idleTime;
  final List<String> memberChannels;
  final List<String> opChannels;
  final List<String> voiceChannels;
  final List<String> channels;
  final List<String> halfOpChannels;
  final List<String> ownerChannels;

  UserInfo(this.bot, this.network, this.nickname,
           this.username, this.realname, this.isAway,
           this.awayMessage, this.isServerOperator,
           this.hostname, this.isIdle, this.idleTime,
           this.memberChannels, this.opChannels, this.voiceChannels,
           this.halfOpChannels, this.ownerChannels, this.channels);
}