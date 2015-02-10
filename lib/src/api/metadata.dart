part of polymorphic.api;

class Command {
  final String name;
  final String permission;
  final String description;
  final String usage;
  final dynamic prefix;
  final bool allowVariables;
  
  const Command(this.name, {this.permission, this.prefix, this.description, this.usage, this.allowVariables});
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

class OnCommand {
  const OnCommand();
}

class Start {
  const Start();
}

class Shutdown {
  const Shutdown();
}

class PluginStorage {
  final String name;
  final String group;
  final bool saveOnChange;
  
  const PluginStorage(this.name, {this.group, this.saveOnChange: true});
}

class FromConfig {
  final String name;
  
  FromConfig(this.name);
}

class OnPart {
  final String network;
  final String user;
  final String channel;
  
  const OnPart({this.network, this.user, this.channel});
}

class OnQuit {
  final String network;
  final String user;
  
  const OnQuit({this.network, this.user});
}

/**
 * Annotation that marks a function that is called only if the specified plugin is installed. This is called when all plugins are ready.
 */
class NotifyPlugin {
  final String plugin;
  
  const NotifyPlugin(this.plugin);
}

class OnKick {
  const OnKick();
}

class OnPluginsReady {
  const OnPluginsReady();
}

class OnServerSupports {
  const OnServerSupports();
}

class OnNickChange {
  const OnNickChange();
}

class OnNickInUse {
  const OnNickInUse();
}

class OnMOTD {
  const OnMOTD();
}

class OnQuitPart {
  final String network;
  final String channel;
  final String user;
  
  const OnQuitPart({this.network, this.channel, this.user});
}

class RemoteMethod {
  final String name;
  final bool isVoid;
  
  const RemoteMethod({this.name, this.isVoid});
}

class OnBotReady {
  final String network;
  
  const OnBotReady({this.network});
}

class OnAction {
  final String network;
  final String target;
  final String message;
  final String user;
  
  const OnAction({this.network, this.target, this.message, this.user});
}

class OnBotJoin {
  final String network;
  final String channel;
  
  const OnBotJoin({this.network, this.channel});
}

class OnCTCP {
  final String network;
  final String target;
  final String message;
  final String user;
  
  const OnCTCP({this.network, this.target, this.message, this.user});
}

class OnNotice {
  final String pattern;
  
  const OnNotice({this.pattern});
}

class OnBotPart {
  final String network;
  final String channel;
  
  const OnBotPart({this.network, this.channel});
}

class OnMessage {
  final String pattern;
  final bool regex;
  final bool ping;
  final bool caseSensitive;
  
  const OnMessage({this.pattern, this.regex: false, this.ping, this.caseSensitive: false});
}

class BotInstance {
  const BotInstance();
}

class PluginInstance {
  const PluginInstance();
}

class HttpEndpoint {
  final dynamic path;
  
  const HttpEndpoint(this.path);
}

class WebSocketEndpoint {
  final String path;
  
  const WebSocketEndpoint(this.path);
}

class DefaultEndpoint {
  const DefaultEndpoint();
}