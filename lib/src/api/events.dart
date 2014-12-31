part of polymorphic.api;

typedef void CommandHandler(CommandEvent event);
typedef void MessageHandler(MessageEvent event);

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
    bot.message(network, target, msg);
  }
}