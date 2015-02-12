import "package:polymorphic_bot/bot.dart";
import "package:analyzer/analyzer.dart";

const String CONTENT = """
import "package:polymorphic_bot/plugin.dart";

const dependencies = {
  "html5lib": ">=0.12.0 <0.13.0"
};
""";

void main() {
  var content = CONTENT;
  var unit = parseCompilationUnit(content);
  var visitor = new ConstantValuesVisitor();
  unit.visitChildren(visitor);
  print(visitor.values);
  var exportsPlugin = unit.directives.any((x) {
    if (x is! ExportDirective) {
      return false;
    }
    
    var uri = stringLiteralToString(x.uri);
    
    if (uri != "package:polymorphic_bot/plugin.dart") {
      return false;
    }
    
    return true;
  });
  print("Exports Plugin: ${exportsPlugin}");
  
  var lines = new List<String>.from(content.split("\n"));
  var exporter = 'export "package:polymorphic_bot/plugin.dart";';
  
  if (!unit.directives.any((x) => x is ImportDirective)) {
    lines.insert(0, exporter);
    content = lines.join("\n");
  } else {
    var lastImport = unit.directives.where((x) => x is ImportDirective).last;
    var endIndex = lastImport.end;
    var chars = new List<String>.generate(content.length, (x) => content[x]);
    chars.insertAll(endIndex, new List<String>.generate(exporter.length, (x) => exporter[x])..insert(0, "\n"));
    content = chars.join();
  }
  
  print(content);
}
