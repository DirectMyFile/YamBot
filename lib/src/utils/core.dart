part of polymorphic.utils;

typedef void Action();

void debug(Action action) {
  if (DEBUG) {
    action();
  }
}

bool get DEBUG {
  if (Zone.current["debug"] == true) {
    return true;
  }
  
  try {
    assert(false);
  } on AssertionError catch (e) {
    return true;
  }
  
  return false;
}

String getFileName(String path) {
  return path.split(Platform.pathSeparator).last;
}

class ProcessUtils {
  static Future<BetterProcessResult> execute(String executable, List<String> args, {Directory workingDirectory}) async {
    var combined = new StringBuffer();
    var stdout = new StringBuffer();
    var stderr = new StringBuffer();
    var process = await Process.start(executable, args, workingDirectory: workingDirectory.absolute.path);
    process.stdout.transform(UTF8.decoder).listen((data) {
      combined.write(data);
      stdout.write(data);
    });
    
    process.stderr.transform(UTF8.decoder).listen((data) {
      combined.write(data);
      stderr.write(data);
    });
    
    var exitCode = await process.exitCode;
    
    return new BetterProcessResult(stdout.toString(), stderr.toString(), combined.toString(), exitCode);
  }
}

class BetterProcessResult {
  final String stdout;
  final String stderr;
  final String output;
  final int exitCode;
  
  BetterProcessResult(this.stdout, this.stderr, this.output, this.exitCode);
  
  void printOutput() {
    for (var line in output.split("\n")) {
      print(line);
    }
  }
}

/**
 * Information about the current environment.
 */
class EnvironmentUtils {
  /**
   * Detects when the current isolate has been compiled by a compiler.
   */
  static bool isCompiled() {
    return new bool.fromEnvironment("compiled", defaultValue: false);
  }
  
  static File getPubSpecFile() {
    var scriptFile = getScriptFile();
    var directoryName = getFileName(scriptFile.parent.path);
    var rootDir;
    
    if (directoryName == "bin") {
      rootDir = scriptFile.parent.parent;
    } else {
      rootDir = scriptFile.parent;
    }
    
    return new File("${rootDir.path}/pubspec.yaml");
  }
  
  static File getScriptFile() {
    var uri = Platform.script;

    return new File(uri.toFilePath());
  }
  
  /**
   * Detects when the current isolate is more than likely a plugin.
   */
  static bool isPlugin() {
    try {
      currentMirrorSystem().findLibrary(#polymorphic.bot);
      return false;
    } catch (e) {
    }
    
    LibraryMirror lib;
    
    try {
      lib = currentMirrorSystem().findLibrary(#polymorphic.api);
    } catch (e) {
      return false;
    }
    
    InstanceMirror loadedM;
    
    try {
      loadedM = lib.getField(#_createdPlugin);
    } catch (e) {
      return false;
    }
    
    return lib != null && loadedM.reflectee == true;
  }
}
