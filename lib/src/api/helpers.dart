part of polymorphic.api;

class Pair<A, B> {
  A a;
  B b;

  Pair(this.a, this.b);

  int get hashCode => hash2(a, b);
  bool operator ==(obj) => obj is Pair<A, B> && obj.a == a && obj.b == b;
}

/**
 * Helpers to display things.
 */
class DisplayHelpers {
  /**
   * Calls [handler] with the page number and items with the given amount [per] items.
   */
  static void paginate(List<dynamic> allItems, int per,
      void handler(int page, List<dynamic> items)) {
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

          if (isDigit(char)) {
            i++;
          }
        }

        if (i < length) {
          char = input[i];

          if (char == ",") {
            i++;

            if (i < length) {
              char = input[i];

              if (isDigit(char)) {
                i++;

                if (i < length) {
                  char = input[i];

                  if (isDigit(char)) i++;
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

    return cleanFormatting(buff.toString());
  }
  
  static String cleanFormatting(String input) {
    var length = input.length;
		var buff = new StringBuffer();
		for (int i = 0; i < length; i++) {
			var ch = input[i];
			if (ch != '\u000f' && ch != '\u0002' && ch != '\u001f' && ch != '\u0016') {
				buff.write(ch);
			}
		}
		return buff.toString();
  }

  static final List<Color> COLORS = [
    Color.RED,
    Color.OLIVE,
    Color.YELLOW,
    Color.GREEN,
    Color.BLUE,
    Color.PURPLE
  ];

  static String rainbowColor(String message) {
    var random = new Random();
    var buff = new StringBuffer();
    var i = 0;
    for (var x = 0; x < message.length; x++) {
      buff.write(COLORS[i]);
      i++;
      if (i == COLORS.length - 1) {
        i = 0;
      }
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

class ProcessHelper {
  static Future<String> getStdout(String executable, List<String> args) {
    return Process.run(executable, args).then((result) {
      return result.stdout;
    });
  }

  static Future<ProcessResult> run(String executable, List<String> args) {
    return Process.run(executable, args);
  }
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

Future<String> shortenUrl(String input,
    {String key: "AIzaSyBNTRakVvRuGHn6AVIhPXE_B3foJDOxmBU"}) {
  return http
      .post("https://www.googleapis.com/urlshortener/v1/url?key=${key}",
          body: JSON.encode({"longUrl": input}),
          headers: {"Content-Type": "application/json"})
      .then((response) {
    if (!([200, 201].contains(response.statusCode))) {
      return input;
    }

    return JSON.decode(response.body)["id"];
  });
}

Future<dynamic> fetch(String url, {Map<String, String> headers: const {}, Map<String, String> query}) {
  if (query != null) {
    url += HttpHelper.buildQueryString(query);
  }

  return _bot.plugin.httpClient.get(url, headers: headers).then((response) {
    if (response.statusCode != 200) {
      throw new HttpError(
          "failed to fetch data", response.statusCode, response.body);
    }

    return response.body;
  });
}

Future<dynamic> fetchJSON(String url, {String transform(String input), Map<String, String> headers: const {}, Map<String, String> query, Type type}) {
  if (query != null) {
    url += HttpHelper.buildQueryString(query);
  }

  return _bot.plugin.httpClient.get(url, headers: headers).then((response) {
    if (response.statusCode != 200) {
      throw new HttpError("failed to fetch JSON", response.statusCode, response.body);
    }

    var out = jsonx.decode(
        transform != null ? transform(response.body) : response.body,
        type: type);
    if (out is Map) {
      out = new SimpleMap(out);
    }
    return out;
  });
}

Future<dynamic> fetchYAML(String url, {String transform(String input), Map<String, String> headers: const {}, Map<String, String> query}) {
  if (query != null) {
    url += HttpHelper.buildQueryString(query);
  }

  return _bot.plugin.httpClient.get(url, headers: headers).then((response) {
    if (response.statusCode != 200) {
      throw new HttpError("failed to fetch YAML", response.statusCode, response.body);
    }

    return yaml.loadYaml(transform != null ? transform(response.body) : response.body);
  });
}

Future<dynamic> postJSON(String url, dynamic body, {Map<String, String> headers: const {}, Map<String, String> query, Type type}) {
  if (query != null) {
    url += HttpHelper.buildQueryString(query);
  }

  return _bot.plugin.httpClient
      .post(url, body: JSON.encode(body), headers: {"Content-Type": "application/json"}..addAll(headers))
      .then((response) {
    if (!([200, 201].contains(response.statusCode))) {
      throw new HttpError("failed to post JSON", response.statusCode, response.body);
    }

    var out = jsonx.decode(response.body, type: type);
    
    if (out is Map) {
      out = new SimpleMap(out);
    }
    return out;
  });
}

Future<HtmlDocument> fetchHTML(String url, {Map<String, String> headers: const {}, Map<String, String> query}) {
  if (query != null) {
    url += HttpHelper.buildQueryString(query);
  }

  return _bot.plugin.httpClient.get(url, headers: headers).then((response) {
    if (response.statusCode != 200) {
      throw new HttpError("failed to fetch HTML", response.statusCode, response.body);
    }

    return new HtmlDocument(parseHtml(response.body));
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

@proxy
class SimpleMap extends DelegatingMap {
  SimpleMap(Map map) : super(map);

  Object get(String key, [Object defaultValue]) {
    if (containsKey(key)) {
      var value = this[key];
      if (value is! SimpleMap && value is Map) {
        value = new SimpleMap(value);
        this[key] = value;
      } else if (value is! _ListWrapper && value is List) {
        value = new _ListWrapper.wrap(value);
        this[key] = value;
      }
      return value;
    } else if (defaultValue != null) {
      return defaultValue;
    }
    return null;
  }

  noSuchMethod(Invocation invocation) {
    var key = MirrorSystem.getName(invocation.memberName);
    if (invocation.isGetter) {
      return get(key);
    } else if (invocation.isSetter) {
      this[key.substring(0, key.length - 1)] =
          invocation.positionalArguments.first;
    } else {
      super.noSuchMethod(invocation);
    }
  }
}

class _ListWrapper extends DelegatingList {
  _ListWrapper(List list) : super(list);

  factory _ListWrapper.wrap(List list) {
    list = list.map((e) {
      if (e is Map && e is! SimpleMap) {
        return new SimpleMap(e);
      } else if (e is List && e is! _ListWrapper) {
        return new _ListWrapper.wrap(e);
      }
      return e;
    }).toList();
    return new _ListWrapper(list);
  }
}

class MessagePen {
  String _content;

  MessagePen([String content = ""]) : _content = content;

  MessagePen blue([String msg]) => color(Color.BLUE, msg);
  MessagePen red([String msg]) => color(Color.RED, msg);
  MessagePen green([String msg]) => color(Color.GREEN, msg);
  MessagePen gold([String msg]) => color(Color.YELLOW, msg);
  MessagePen yellow([String msg]) => color(Color.YELLOW, msg);
  MessagePen orange([String msg]) => color(Color.OLIVE, msg);
  MessagePen olive([String msg]) => color(Color.OLIVE, msg);
  MessagePen bold([String msg]) => color(Color.BOLD, msg);

  MessagePen color(String color, String msg) {
    if (msg == null) {
      write(color);
    } else {
      write(color);
      write(msg);
      write(Color.RESET);
    }
    return this;
  }

  MessagePen reset() => write(Color.RESET);

  MessagePen newLine() => write("\n");

  MessagePen write(String msg) {
    _content += msg;
    return this;
  }

  @override
  String toString() => _content;
  
  String end() => toString();
}

List<String> charactersOf(String input) =>
    new List<String>.generate(input.length, (i) => input[i]);

bool isDigit(String it) =>
    ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].contains(it);
bool isInteger(String it) => charactersOf(it).every((c) => isDigit(c));
