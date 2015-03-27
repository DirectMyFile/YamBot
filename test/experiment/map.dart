import "package:polymorphic_bot/api.dart" show SimpleMap, parseJSON;

void main() {
  var m = new SimpleMap({
    "hello": "Hello World",
    "test": [
      {
        "hi": "Hello",
        "bye": "Goodbye"
      }
    ]
  });

  print(m.hello);
  print(m.test[0].hi);

  var out = parseJSON("""
  {
    "hello": "Hello World",
    "test": [
      {
        "hi": "Hello",
        "bye": "Goodbye"
      }
    ]
  }
  """);

  print(out.hello);
  print(out.test[0].hi);
}
