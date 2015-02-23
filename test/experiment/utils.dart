import "package:polymorphic_bot/utils.dart";

void main() {
  print(StringUtils.multiple("# # cool.", ["It", "is"], ["They", "are"], 2));
  print(StringUtils.splitByAll("ABCDEFG", ["B", "E"]));
}