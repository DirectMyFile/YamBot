/**
 * # Plugin Helper
 * 
 * This provides a helper that you can export from your plugin's main script.
 * It will automatically load your plugin.
 * 
 * ## Example:
 * ```dart
 * import "package:polymorphic_bot/plugin.dart";
 * export "package:polymorphic_bot/plugin.dart";
 * 
 * @Command("hi")
 * hi(event) => event.reply("> Hello!");
 * ```
 */
library polymorphic.plugin;

import "package:polymorphic_bot/api.dart";
export "package:polymorphic_bot/api.dart";

export "dart:io";

export "package:quiver/async.dart";
export "package:quiver/strings.dart";
export "package:quiver/core.dart";

export "package:http_server/http_server.dart";
export "package:irc/client.dart" show Color;
export "package:jsonx/jsonx.dart" show jsonIgnore, jsonProperty, jsonObject;

void main(List<String> args, port) {
  polymorphic(args, port);
}
