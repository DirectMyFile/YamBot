part of polymorphic.api;

class DisplayHelpers {
  static void paginate(List<dynamic> allItems, int per, void handler(int page, List<dynamic> items)) {
    var x = 0;
    var buff = [];
    var p = 1;
    for (var i = 0; i < allItems.length; i++) {
      x++;
      buff.add(allItems[i]);
      if (x == per || i + 1 == allItems.length) {
        handler(p, new List<dynamic>.from(buff));
        x = 0;
        buff.clear();
        p++;
      }
    }
  }
  
  static bool fitsInSingleMessage(String input) =>
      input.length <= 400;
}
