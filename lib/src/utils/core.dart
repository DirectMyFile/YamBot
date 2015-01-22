part of polymorphic.utils;

typedef void Action();

void debug(Action action) {
  if (DEBUG) {
    action();
  }
}

final bool DEBUG = (() {
  if (Zone.current["debug"] == true) {
    return true;
  }
  
  try {
    assert(false);
  } on AssertionError catch (e) {
    return true;
  }
  return false;
})();

class EnvironmentUtils {
  static const List<String> _compiledHints = const [
    "class DefaultEquality implements Equality {", // from collection package
    "abstract class _UnorderedEquality<E, T extends Iterable<E>> implements Equality<T> {", // from collection package
    "class ScalarEvent extends _ValueEvent {" // from yaml package
  ];
  
  /**
   * Attempts to determine if the root script of this isolate
   * is likely compiled with some sort of tool.
   * 
   * [uncompiledMaxLines] is the maximum number of lines of the root script that you expect when it is not compiled.
   * [compiledLineIndex] is the index of a line in the compiled output that has a large width.
   * [compiledLineWidth] is the minimum length of the line at [compiledLineIndex] that we expect.
   */
  static bool isCompiled({int uncompiledMaxLines: 1000, int compiledLineIndex: 0, int compiledLineWidth: 5000}) {
    var script = Platform.script;
    
    if (script == null || script.scheme != "file") {
      return false;
    }
    
    var file = new File.fromUri(script);
    var lines = file.readAsLinesSync();
    var content = lines.join("\n");
    
    // These are almost always present in some way.
    if (_compiledHints.every((hint) => content.contains(hint))) {
      return true;
    }
    
    return lines.length > uncompiledMaxLines || lines[compiledLineIndex].length >= compiledLineWidth;
  }
  
  static bool isLikelyPlugin() {
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