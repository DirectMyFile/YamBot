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
