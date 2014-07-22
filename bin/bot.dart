import "package:polymorphic_bot/bot.dart";

main(List<String> args) {
  if (args.length != 1) {
    print("Usage: bot <working directory>");
    return;
  }
  launchBot(args[0]);
}