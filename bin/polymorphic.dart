import "dart:async";
import "dart:io";

import "package:args/command_runner.dart";
import "package:polymorphic_bot/bot.dart";

const String SCRIPT_TEMPLATE = """
import "package:polymorphic_bot/plugin.dart";
export "package:polymorphic_bot/plugin.dart";

@PluginInstance()
Plugin plugin;

@BotInstance()
BotConnector bot;

@Command("example")
example(CommandEvent event) {
  event.reply("Example Command.");
}
""";

void main(List<String> args) {
  var runner = new CommandRunner("polymorphic", "PolymorphicBot");
  runner.argParser.addFlag("debug", abbr: "d", help: "Enable Debugging");
  runner.addCommand(new StartCommand());
  runner.addCommand(new CreateScriptCommand());
  
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

class CreateScriptCommand extends Command {
  CreateScriptCommand() {
    argParser.addOption("name", abbr: "n", help: "Script Name");
  }

  @override
  String get description => "Creates a Script";

  @override
  String get name => "create-script";

  @override
  void run() {
    if (!argResults.options.contains("name")) {
      print("ERROR: Please specify the name of the script via the -n parameter.");
      exit(1);
    }

    var file = new File("${argResults["name"]}.dart");

    file.writeAsStringSync(SCRIPT_TEMPLATE);
  }
}