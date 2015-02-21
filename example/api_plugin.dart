import "package:polymorphic_bot/plugin.dart";
export "package:polymorphic_bot/plugin.dart";

@BotInstance()
BotConnector bot;
@PluginInstance()
Plugin plugin;

@RemoteMethod()
String greet() => "Hello World";

@RemoteMethod()
void doStuff() {
  print("Do Something.");
}

@Start()
start() {
  // Calls another plugin's remote method.
  plugin.callRemoteMethod("SomePlugin", "sayHi", "Alex").then((result) {
    print(result);
  });
  
  // Call an advanced remote method.
  plugin.callRemoteMethod("SomePlugin", "doStuff", {
    "something": "Hello World"
  }).then((result) {
    print(result["test"]);
  });
}
