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

void main(List<String> args, port) {
  polymorphic(args, port);
}
