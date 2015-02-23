part of polymorphic.utils;

class StringUtils {
  static String reverse(String input) => new String.fromCharCodes(input.codeUnits.reversed);
  static String capitalize(String input) {
    if (input.isEmpty) {
      return "";
    } else {
      return input[0].toUpperCase() + input.substring(1);
    }
  }
  
  static String insert(String input, int index, String str) {
    var ic = characters(input);
    var sc = characters(str);
    ic.insertAll(index, sc);
    return ic.join();
  }
  
  static List<String> characters(String input) => new List<String>.generate(input.length, (i) => input[i]);
  static bool isWhitespace(String input) => input.trim().isEmpty;
  static String multiple(String input, List<String> ones, List<String> mores, int length) {
    List<String> pool;
    if (length == 1) {
      pool = ones;
    } else {
      pool = mores;
    }
    var index = -1;
    return input.replaceAllMapped("#", (match) => pool[++index]);
  }
}