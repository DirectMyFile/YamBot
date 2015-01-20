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
    
  static String clean(String input) {
    StringBuffer buff = new StringBuffer();
        int length = input.length;
        int i = 0;
        
        while (i < length) {
          var char = input[i];
          if (char == "\u0003") {
            i++;
            
            if (i < length) {
              i++;
              char = input[i];
              
              if (_isDigit(char)) {
                i++;
              }
            }
            
            if (i < length) {
              char = input[i];
              
              if (char == ",") {
                i++;
                
                if (i < length) {
                  char = input[i];
                  
                  if (_isDigit(char)) {
                    i++;
                    
                    if (i < length) {
                      char = input[i];
                      
                      if (_isDigit(char))
                        i++;
                    }
                  }
                }
              }
            }
          } else if (char == "\u000f") {
            i++;
          } else {
            buff.write(char);
            i++;
          }
        }
        
        return buff.toString();
  }
}

bool _isDigit(String it) =>
    ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].contains(it);
