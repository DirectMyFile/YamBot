part of polymorphic.api;

typedef void CommandHandler(CommandEvent event);

class EventManager {
  final BotConnector bot;
  
  StreamSubscription _eventSub;
  
  final Map<String, StreamController> _controllers = {};
  
  EventManager(this.bot);
  
  void apply() {
    _eventSub = bot.handleEvent(handleEvent);
    onShutdown(() {
      _eventSub.cancel();
      
      for (var controller in _controllers.values) {
        controller.close();
      }
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
  
  void command(String name, CommandHandler handler) {
    on("command").where((data) => data['command'] == name).listen((data) {
      var command = data['command'];
      var args = data['args'];
      var user = data['from'];
      var channel = data['target'];
      var network = data['network'];
      var message = data['message'];
      
      handler(new CommandEvent(bot, network, command, message, user, channel, args));
    });
  }
  
  void onShutdown(void action()) {
    on("shutdown").listen((_) => action());
  }
  
  void handleEvent(Map<String, dynamic> data) {
    String name = data['event'];
    
    if (_controllers.containsKey(name)) _controllers[name].add(data);
  }
}