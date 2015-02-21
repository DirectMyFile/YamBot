part of polymorphic.api;

typedef CommandHandler(CommandEvent event);
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
typedef void NickChangeHandler(NickChangeEvent event);
typedef void NickInUseHandler(NickInUseEvent event);
typedef void ServerSupportsHandler(ServerSupportsEvent event);
typedef void MOTDHandler(MOTDEvent event);
typedef void KickHandler(KickEvent event);

typedef void ShutdownAction();

class NickChangeEvent {
  final BotConnector bot;
  final String network;
  final String original;
  final String now;
  
  NickChangeEvent(this.bot, this.network, this.original, this.now);
}

class KickEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  final String user;
  final String kicker;
  final String reason;
  
  KickEvent(this.bot, this.network, this.channel, this.user, this.kicker, this.reason);
}

class MOTDEvent {
  final BotConnector bot;
  final String network;
  final String message;
  
  MOTDEvent(this.bot, this.network, this.message);
}

class ServerSupportsEvent {
  final BotConnector bot;
  final String network;
  final Map<String, dynamic> supported;
  
  ServerSupportsEvent(this.bot, this.network, this.supported);
}

class NickInUseEvent {
  final BotConnector bot;
  final String network;
  final String original;
  
  NickInUseEvent(this.bot, this.network, this.original);
  
  void useNickname(String nick) {
    bot.changeBotNickname(network, nick);
  }
  
  void append(String suffix) {
    bot.changeBotNickname(network, original + suffix);
  }
}

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

  StorageContainer getUserMetadata({bool channelSpecific: false}) {
    return bot.getUserMetadata(network, channel, user, channelSpecific: channelSpecific);
  }
  
  StorageContainer getChannelMetadata() {
    return bot.getChannelMetadata(network, channel);
  }
  
  ModeEvent(this.bot, this.network, this.channel, this.user, this.mode);
}

class TopicEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  final String oldTopic;
  final String topic;
  final String user;
  
  bool get isChangeEvent => user != null;
  
  StorageContainer getChannelMetadata() {
    return bot.getChannelMetadata(network, channel);
  }
  
  void revert() {
    bot.setChannelTopic(network, channel, oldTopic);
  }

  TopicEvent(this.bot, this.network, this.channel, this.user, this.topic, this.oldTopic);
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

  StorageContainer getUserMetadata({bool channelSpecific: false}) {
    return bot.getUserMetadata(network, channel, user, channelSpecific: channelSpecific);
  }
  
  StorageContainer getChannelMetadata() {
    return bot.getChannelMetadata(network, channel);
  }
  
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
  final bool isPing;
  final bool isCommand;
  final Match match;

  String get user => from;
  String get channel => target;

  MessageEvent(this.bot, this.network, this.target, this.from, this.isPrivate, this.isPing, this.isCommand, this.message, {this.match});

  /**
   * Sends [message] as a message to [channel] on [network].
   *
   * If [prefix] is prefixed with [prefixContent].
   * If [prefixContent] is empty it becomes the display name of this plugin.
   */
  void reply(String message, {bool prefix, String prefixContent}) {
    if (prefix || (prefix == null && prefixContent != null)) {
      if (prefixContent == null) {
        prefixContent = bot.plugin.displayName;
      }

      message = "[${Color.BLUE}${prefixContent}${Color.RESET}] ${message}";
    }

    bot.sendMessage(network, channel, message);
  }
  
  void executeCommand(String command, [List<String> args = const []]) {
    bot.executeCommand(network, channel, user, command, args);
  }
  
  /**
   * Sends [message] as a message to [channel] on [network].
   *
   * If [prefix] is prefixed with [prefixContent].
   * If [prefixContent] is empty it becomes the display name of this plugin.
   */
  void replyNotice(String message, {bool prefix, String prefixContent}) {
    if (prefix || (prefix == null && prefixContent != null)) {
      if (prefixContent == null) {
        prefixContent = bot.plugin.displayName;
      }

      message = "[${Color.BLUE}${prefixContent}${Color.RESET}] ${message}";
    }

    bot.sendNotice(network, user, message);
  }
  
  Future<BufferEntry> getLastChannelMessage() {
    return getChannelBuffer().then((entries) => entries.first);
  }
  
  Future<List<BufferEntry>> getChannelBuffer() => bot.getChannelBuffer(network, channel);

  operator <<(msg) {
    if (msg == null) {
      return;
    }

    if (msg is NoArgumentFunction) {
      var value = msg();

      if (value == null) {
        return;
      }

      if (value is Future) {
        value.then((msg) {
          if (msg == null) {
            return;
          }

          reply(msg);
        });
        return;
      }
    } else if (msg is List) {
      random(msg);
    } else {
      reply(msg.toString());
    }
  }

  operator <(String msg) {
    replyNotice(msg);
  }

  String operator ~() {
    return message;
  }

  Future<String> getLastCommand([bool userOnly = true]) {
    return bot.plugin.callMethod("getLastCommand", {
      "network": network,
      "channel": channel
    }..addAll(userOnly ? { "user": user } : {}));
  }

  void random(List<String> messages) {
    var r = new Random();
    reply(messages[r.nextInt(messages.length)]);
  }
  
  void kickUser({String reason}) {
    bot.kick(network, target, from, reason: reason);
  }
  
  void banUser() {
    bot.ban(network, target, from);
  }
  
  StorageContainer getUserMetadata({bool channelSpecific: false}) {
    return bot.getUserMetadata(network, channel, user, channelSpecific: channelSpecific);
  }
  
  StorageContainer getChannelMetadata() {
    return bot.getChannelMetadata(network, channel);
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
  
  void kick({String reason}) {
    bot.kick(network, channel, user, reason: reason);
  }
  
  void kickBan({String reason}) {
    bot.kickBan(network, channel, user, reason: reason);
  }
  
  StorageContainer getUserMetadata({bool channelSpecific: false}) {
    return bot.getUserMetadata(network, channel, user, channelSpecific: channelSpecific);
  }
  
  StorageContainer getChannelMetadata() {
    return bot.getChannelMetadata(network, channel);
  }
  
  void ban() {
    bot.ban(network, channel, user);
  }
}

class PartEvent {
  final BotConnector bot;
  final String network;
  final String channel;
  final String user;

  StorageContainer getUserMetadata({bool channelSpecific: false}) {
    return bot.getUserMetadata(network, channel, user, channelSpecific: channelSpecific);
  }
  
  StorageContainer getChannelMetadata() {
    return bot.getChannelMetadata(network, channel);
  }
  
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
  
  void part() {
    bot.partChannel(network, channel);
  }
}

class BotPartEvent {
  final BotConnector bot;
  final String network;
  final String channel;

  BotPartEvent(this.bot, this.network, this.channel);
  
  void rejoin() {
    bot.joinChannel(network, channel);
  }
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

class BufferEntry {
  final String network;
  final String target;
  final String user;
  final String message;

  BufferEntry(this.network, this.target, this.user, this.message);

  factory BufferEntry.fromData(Map data) {
    String network = data['network'];
    String target = data['target'];
    String message = data['message'];
    String user = data['from'];

    return new BufferEntry(network, target, user, message);
  }
  
  Map toData() => {
    "network": network,
    "target": target,
    "from": user,
    "message": message
  };
}