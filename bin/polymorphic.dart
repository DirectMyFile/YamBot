import "package:args/command_runner.dart";
import "package:polymorphic_bot/bot.dart";

void main(List<String> args) {
  var runner = new CommandRunner("polymorphic", "PolymorphicBot");
  runner.addCommand(new StartCommand());
  
  runner.run(args);
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