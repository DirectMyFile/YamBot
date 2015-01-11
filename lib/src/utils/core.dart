part of polymorphic.utils;

typedef void Action();

void debug(Action action) {
  if (DEBUG) {
    action();
  }
}

final bool DEBUG = (() {
  try {
    assert(false);
  } on AssertionError catch (e) {
    return true;
  }
  return false;
})();