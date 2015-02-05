library polymorphic.grind;

import "dart:io";

import "package:grinder/grinder.dart";
import "package:yaml/yaml.dart";

void main(List<String> args) {
  task("clean", defaultClean);
  task("package", package);
  task("package-dev", packageUnminified);
  task("test", test);
  task("analyze", analyze);
  
  task("build", null, ["clean", "package", "package-dev"]);
  task("ci", null, ["analyze", "test", "build"]);
  
  startGrinder(args);
}

test(GrinderContext context) {
  runDartScript(context, "test/all.dart");
}

analyze(GrinderContext context) {
  Analyzer.analyzePaths(context, [
    "lib/bot.dart",
    "lib/api.dart",
    "lib/slack.dart",
    "lib/plugin.dart",
    "lib/utils.dart"
  ]);
}

package(GrinderContext context) {
  return compile(context, true);
}

packageUnminified(GrinderContext context) {
  return compile(context, false, file: "build/out/PolymorphicBot-unminified.dart");
}

compile(GrinderContext context, bool minify, {String file: "build/out/PolymorphicBot.dart"}) {
  ensureOutDirectory();
  var pubspec = loadYaml(new File("pubspec.yaml").readAsStringSync());
  var version = pubspec["version"];
  
  var args = [
    "--enable-experimental-mirrors",
    "--categories=Server",
    "--output-type=dart",
    "bin/polymorphic.dart",
    "-o",
    file,
    "-Dcompiled=true",
    "-Dversion=${version}",
    "--trust-type-annotations",
    "--trust-primitives"
  ];
  
  if (minify) {
    args.add("-m");
  }
  
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
