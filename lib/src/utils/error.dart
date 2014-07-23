part of polymorphic.utils;

void error({String prefix, String message: "unknown", bool shouldExit: true, int exitCode: 1}) {
  var buff = new StringBuffer();
  
  if (prefix != null) {
    buff.write("[${prefix}] ");
  }
  
  buff.write(message);
  
  print(buff.toString());
  
  if (shouldExit) {
    exit(exitCode);
  }
}