library polymorphic.grind;

import "package:grinder/grinder.dart";

void main(List<String> args) {
  task("clean", defaultClean);
  task("package", package);
  task("build", null, ["clean", "package"]);
  task("test", test);
  task("ci", null, ["test", "build"]);
  
  startGrinder(args);
}

test(GrinderContext context) {
  runDartScript(context, "test/all.dart");
}

package(GrinderContext context) {
  ensureOutDirectory();
  
  var args = [
    "--enable-experimental-mirrors",
    "--categories=Server",
    "--output-type=dart",
    "bin/polymorphic.dart",
    "-o",
    "build/out/PolymorphicBot.dart",
    "-m"
  ];
  
  return runProcessAsync(context, "dart2js", arguments: args).then((_) {
    new FileSet.fromDir(getDir("build/out"), pattern: "*.deps").files.forEach((file) {
      deleteEntity(file);
    });
  });
}

ensureOutDirectory() {
  var dir = getDir("build/out");
  
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}