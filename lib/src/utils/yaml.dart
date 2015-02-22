part of polymorphic.utils;

String encodeYAML(data) {
  var buffer = new StringBuffer();

  _stringify(bool isMapValue, String indent, data) {
    // Use indentation for (non-empty) maps.
    if (data is Map && !data.isEmpty) {
      if (isMapValue) {
        buffer.writeln();
        indent += '  ';
      }

      // Sort the keys. This minimizes deltas in diffs.
      var keys = data.keys.toList();
      keys.sort((a, b) => a.toString().compareTo(b.toString()));

      var first = true;
      for (var key in keys) {
        if (!first) buffer.writeln();
        first = false;

        var keyString = key;

        if (key is! String || !_unquotableYamlString.hasMatch(key)) {
          keyString = JSON.encode(key);
        }

        if (key == "*") {
          keyString = '"*"';
        }

        buffer.write('$indent$keyString:');
        _stringify(true, indent, data[key]);
      }

      return;
    }

    // Everything else we just stringify using JSON to handle escapes in
    // strings and number formatting.
    var string = data;

    // Don't quote plain strings if not needed.
    if (data is! String || !_unquotableYamlString.hasMatch(data)) {
      string = JSON.encode(data);
    }

    if (isMapValue) {
      buffer.write(' $string');
    } else {
      buffer.write('$indent$string');
    }
  }

  _stringify(false, '', data);
  return buffer.toString();
}

final _unquotableYamlString = new RegExp(r"^[a-zA-Z_-][a-zA-Z_0-9-]*$");

dynamic crawlYAML(input) {
  if (input == null) {
    return null;
  } else if (input is List) {
    var out = [];
    for (var value in input) {
      out.add(crawlYAML(value));
    }
    return out;
  } else if (input is Map) {
    var out = {};
    for (var key in input.keys) {
      out[crawlYAML(key)] = crawlYAML(input[key]);
    }
    return out;
  } else {
    return input;
  }
}

