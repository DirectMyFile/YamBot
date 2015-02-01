import "package:polymorphic_bot/bot.dart";
import "package:analyzer/analyzer.dart";

void main() {
  var unit = parseCompilationUnit("""
const dependencies = {
  "html5lib": ">=0.12.0 <0.13.0"
};
""");
  var visitor = new ConstantValuesVisitor();
  unit.visitChildren(visitor);
  print(visitor.values);
}