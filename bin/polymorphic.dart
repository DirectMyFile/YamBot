import "dart:async";
import "dart:convert";
import "dart:io";

import "package:polymorphic_bot/utils.dart";
import "package:polymorphic_bot/launcher.dart" deferred as launcher;

main(List<String> args) async {
  await verifyDependencies();
  await launcher.loadLibrary();
  launcher.main(args);
}

var didUpdateDeps = false;

verifyDependencies() async {
  var stateFile = new File(".state.json");
    
  if (!EnvironmentUtils.isCompiled()) {
    var pubspec = EnvironmentUtils.getPubSpecFile();
    var pkgsDir = new Directory("${pubspec.parent.path}/packages");
      
    saveState() async {
      var pubspecContent = await base64File(pubspec);
      var data = {
        "pubspec": pubspecContent
      };
        
      await stateFile.writeAsString(new JsonEncoder.withIndent("  ").convert(data));
    }
      
    updateDependencies() async {
      if (didUpdateDeps) {
        return;
      }
      
      didUpdateDeps = true;
      
      var dir = EnvironmentUtils.getScriptFile().parent.parent;
      print("[Launcher] Fetching Dependencies");
      var result = await Process.run("pub", ["upgrade"], workingDirectory: dir.path);
        
      if (result.exitCode != 0) {
        print("[Launcher] Failed to fetch dependencies!");
        print("STDOUT:");
        print(result.stdout);
        print("STDERR:");
        print(result.stderr);
      }
    }
      
    debug(() => print("[Launcher] Verifying Dependencies"));
      
    var data = {};
    
    if (!pkgsDir.existsSync()) {
      await updateDependencies();  
    }
    
    if (await stateFile.exists()) {
      data = JSON.decode(await stateFile.readAsString());
      var current = await base64File(pubspec);
      var last = data["pubspec"];
        
      if (current != last) {
        await updateDependencies();
      }
        
      await saveState();
    } else {
      await updateDependencies();
      await saveState();
    }
  }
}

base64File(File file) async {
  var bytes = await file.readAsBytes();
  return BasicCryptoUtils.bytesToBase64(bytes);
}
