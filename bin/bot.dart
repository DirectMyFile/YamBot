import "package:polymorphic_bot/bot.dart";

void main(List<String> args) {
  if (args.length > 1) {
    print("Usage: polymorphic [directory]");
    return;
  }
  launchBot(args.length == 1 ? args[0] : ".");
}