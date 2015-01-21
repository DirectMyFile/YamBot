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
    
    return lines.length > uncompiledMaxLines || lines[compiledLineIndex].length >= compiledFirstLineWidth;
  }
}