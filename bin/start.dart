import "package:yambot/yambot.dart";

main(List<String> args) {
  if (args.length != 1) {
    print("Usage: yambot <directory>");
    return;
  }
  launchYamBot(args[0]);
}