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
  
  static String format(String input, List values, {String indicator: "#"}) {
    var index = -1;
    return input.replaceAllMapped(indicator, (match) => values[++index].toString());
  }
  
  static String remove(String input, Pattern pattern) {
    return input.replaceAll(pattern, "");
  }
  
  static String removeAll(String input, List<Pattern> patterns) {
    var out = input;
    for (var pattern in patterns) {
      out = remove(out, pattern);
    }
    return out;
  }
  
  static List<String> splitByAll(String input, List<Pattern> delimiters) {
    var x = "\u0000";
    var out = input;
    for (var delimiter in delimiters) {
      out = out.replaceAll(delimiter, x);
    }
    return out.split(x);
  }
  
  static List<String> characters(String input) => new List<String>.generate(input.length, (i) => input[i]);
  static bool isWhitespace(String input) => input.trim().isEmpty;
  static String multiple(String input, List<String> ones, List<String> mores, int length) {
    return format(input, length == 1 ? ones : mores);
  }
}