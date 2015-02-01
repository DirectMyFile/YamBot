part of polymorphic.api;

/**
 * Helpers to display things.
 */
class DisplayHelpers {
  /**
   * Calls [handler] with the page number and items with the given amount [per] items.
   */
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

  /**
   * Returns true if [input] fits in a single message.
   * 
   * Equivalent to:
   * 
   * ```dart
   * return input.length <= 40;
   * ```
   */
  static bool fitsInSingleMessage(String input) => input.length <= 400;

  /**
   * Removes formatting from [input].
   */
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

                  if (_isDigit(char)) i++;
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
  
  static final List<Color> COLORS = [Color.RED, Color.OLIVE, Color.YELLOW, Color.GREEN, Color.BLUE, Color.PURPLE];
  
  static String rainbowColor(String message) {
    var random = new Random();
    var buff = new StringBuffer();
    for (var x = 0; x < message.length; x++) {
      buff.write(COLORS[random.nextInt(COLORS.length)]);
      buff.write(message[x]);
      buff.write(Color.RESET);
    }
    return buff.toString();
  }
}

/**
 * Helpers for statistics.
 */
class StatisticHelpers {
  /**
   * Calculates the average of the given [inputs].
   */
  static num average(List<num> inputs) {
    return inputs.reduce((a, b) => a + b) / inputs.length;
  }

  /**
   * Counts the amount of times [element] appears in [inputs].
   */
  static int count(List<dynamic> inputs, dynamic element) {
    return inputs.where((it) => it == element).length;
  }

  /**
   * Gets the most common element in [inputs].
   */
  static dynamic mostCommon(List<dynamic> inputs) {
    var list = new List.from(inputs);
    list.sort((a, b) => count(list, b).compareTo(count(list, a)));
    return list.first;
  }

  /**
   * Gets the least common element in [inputs].
   */
  static dynamic leastCommon(List<dynamic> inputs) {
    var list = new List.from(inputs);
    list.sort((a, b) => count(list, a).compareTo(count(list, b)));
    return list.first;
  }
}

Future<Process> runProcess(String executable, List<String> args, {String cwd}) {
  return Process.start(executable, args, workingDirectory: cwd);
}

bool isUrl(String input) {
  try {
    return Uri.parse(input) != null;
  } catch (e) {
    return false;
  }
}

html.Document parseHtml(content, [void handler(HtmlDocument $)]) {
  var doc = htmlParser.parse(content);
  
  if (handler != null) {
    handler(new HtmlDocument(doc));
  }

  return doc;
}

class HtmlDocument {
  final html.Document document;
  
  HtmlDocument(this.document);
  
  html.Element call(String query) {
    return document.querySelector(query);
  }
}

Future<String> shortenUrl(String input, {String key: "AIzaSyBNTRakVvRuGHn6AVIhPXE_B3foJDOxmBU"}) {
  return http.post("https://www.googleapis.com/urlshortener/v1/url?key=${key}", body: JSON.encode({
    "longUrl": input
  }), headers: { "Content-Type": "application/json" }).then((response) {
    if (!([200, 201].contains(response.statusCode))) {
      return input;
    }
    
    return JSON.decode(response.body)["id"];
  });
}

typedef void Task();

class Scheduler {
  Scheduler();
  
  Timer scheduleAt(DateTime time, Task task) {
    var dnow = new DateTime.now();
    var now = dnow.millisecondsSinceEpoch;
    var target = time.millisecondsSinceEpoch;
    
    if (target < now) {
      throw new Exception("Scheduled time was in the past.");
    }
    
    if (target == now) {
      new Future(() {
        task();
      });
      return null;
    }
    
    var delay = target - now;
    
    return new Timer(new Duration(milliseconds: delay), () {
      task();
    });
  }
  
  Timer schedule(Duration delay, Task task) {
    return new Timer(delay, () {
      task();
    });
  }
}

bool _isDigit(String it) => ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].contains(it);
