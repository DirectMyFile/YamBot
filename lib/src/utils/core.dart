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

String encodeYAML(data) {
  var buffer = new StringBuffer();

  _stringify(bool isMapValue, String indent, data) {
    // Use indentation for (non-empty) maps.
    if (data is Map && !data.isEmpty) {
      if (isMapValue) {
        buffer.writeln();
        indent += '  ';
      }

      // Sort the keys. This minimizes deltas in diffs.
      var keys = data.keys.toList();
      keys.sort((a, b) => a.toString().compareTo(b.toString()));

      var first = true;
      for (var key in keys) {
        if (!first) buffer.writeln();
        first = false;

        var keyString = key;
        
        if (key is! String || !_unquotableYamlString.hasMatch(key)) {
          keyString = JSON.encode(key);
        }
        
        if (key == "*") {
          keyString = '"*"';
        }

        buffer.write('$indent$keyString:');
        _stringify(true, indent, data[key]);
      }

      return;
    }

    // Everything else we just stringify using JSON to handle escapes in
    // strings and number formatting.
    var string = data;

    // Don't quote plain strings if not needed.
    if (data is! String || !_unquotableYamlString.hasMatch(data)) {
      string = JSON.encode(data);
    }

    if (isMapValue) {
      buffer.write(' $string');
    } else {
      buffer.write('$indent$string');
    }
  }

  _stringify(false, '', data);
  return buffer.toString();
}

final _unquotableYamlString = new RegExp(r"^[a-zA-Z_-][a-zA-Z_0-9-]*$");

dynamic crawlYAML(input) {
  if (input == null) {
    return null;
  } else if (input is List) {
    var out = [];
    for (var value in input) {
      out.add(crawlYAML(value));
    }
    return out;
  } else if (input is Map) {
    var out = {};
    for (var key in input.keys) {
      out[crawlYAML(key)] = crawlYAML(input[key]);
    }
    return out;
  } else {
    return input;
  }
}
