part of polymorphic.api;

typedef void CommandHandler(CommandEvent event);
typedef void MessageHandler(MessageEvent event);

typedef void ShutdownAction();

class EventManager {
  final BotConnector bot;

  List<StreamSubscription> _subs = [];

  StreamSubscription _eventSub;

  List<ShutdownAction> _shutdown = [];
  
  final Map<String, StreamController> _controllers = {};
  
  EventManager(this.bot);

  bool _isShutdown = false;

  void apply() {
    _eventSub = bot.handleEvent(handleEvent);
    var sub;
    sub = on("shutdown").listen((_) {
      for (var action in _shutdown) {
        action();
      }

      for (var controller in _controllers.values) {
        controller.close();
      }

      _eventSub.cancel();

      for (var s in _subs) {
        s.cancel();
      }

      sub.cancel();

      for (var storage in bot._storages) {
        storage.destroy();
      }

      _isShutdown = true;
    });
  }
  
  void disable() => _eventSub.pause();
  void enable() => _eventSub.resume();
  
  Stream<Map<String, dynamic>> on(String name) {
    if (!_controllers.containsKey(name)) {
      _controllers[name] = new StreamController.broadcast();
    }
    
    return _controllers[name].stream;
  }
  
  void onMessage(MessageHandler handler, {Pattern pattern}) {
    var sub = on("message").map((it) {
      var network = it["network"];
      var target = it["target"];
      var from = it["from"];
      var private = it["private"];
      var message = it["message"];
      
      return new MessageEvent(bot, network, target, from, private, message);
    }).where((MessageEvent it) {
      if (pattern != null) {
        return it.message.allMatches(pattern).isNotEmpty;
      }
      return true;
    }).listen((event) {
      handler(event);
    });
    
    _subs.add(sub);
  }
  
  void command(String name, CommandHandler handler) {
    var sub = on("command").where((data) => data['command'] == name).listen((data) {
      var command = data['command'];
      var args = data['args'];
      var user = data['from'];
      var channel = data['target'];
      var network = data['network'];
      var message = data['message'];
      
      handler(new CommandEvent(bot, network, command, message, user, channel, args));
    });
    
    _subs.add(sub);
  }
  
  void onShutdown(void action()) {
    _shutdown.add(action);
  }

  void registerSubscription(StreamSubscription sub) {
    _subs.add(sub);
  }
  
  void handleEvent(Map<String, dynamic> data) {
    if (_isShutdown) {
      return;
    }

    String name = data['event'];
    
    if (_controllers.containsKey(name)) _controllers[name].add(data);
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
    bot.message(network, target, msg);
  }
}