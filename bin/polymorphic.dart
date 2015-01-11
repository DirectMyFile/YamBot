import "package:args/command_runner.dart";
import "package:polymorphic_bot/bot.dart";
import "dart:async";

void main(List<String> args) {
  var runner = new CommandRunner("polymorphic", "PolymorphicBot");
  runner.argParser.addFlag("debug", abbr: "d", help: "Enable Debugging");
  runner.addCommand(new StartCommand());
  
  var result = runner.parse(args);
  var debug = result["debug"];
  
  Zone.current.fork(zoneValues: {
    "debug": debug
  }).run(() {
    runner.runCommand(result);
  });
}

class StartCommand extends Command {
  StartCommand() {
    argParser.addOption("path", abbr: "p", help: "Path to Working Directory", defaultsTo: ".");
  }
  
  @override
  String get description => "Starts the Bot";

  @override
  String get name => "start";
  
  
  @override
  void run() {
    launchBot(argResults['path']);
  }
}