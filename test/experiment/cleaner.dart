import "package:polymorphic_bot/api.dart";

void main() {
  print(DisplayHelpers.clean("${Color.BLUE}Hello${Color.NORMAL}"));
  print(DisplayHelpers.clean("${Color.BLUE}<Hello>${Color.NORMAL} What is your name?"));
}