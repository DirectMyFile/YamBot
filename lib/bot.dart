library bot;

import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart' as yaml;

import "package:irc/irc.dart" as IRC;
import 'package:plugins/loader.dart';

part 'src/plugins/manager.dart';
part 'src/plugins/handler.dart';
part 'src/config.dart';
part 'src/core.dart';
part 'src/auth.dart';
part 'src/bot.dart';

/**
 * Launches the bot. The [path] will override the current [Directory]
 * and read all configurations from it.
 * Returns [CoreBot].
 */
CoreBot launchBot(String path) {
  var dir = new Directory(path).absolute;
  if (!dir.existsSync()) {
    throw new Exception("'$path' does not exist");
  }
  Directory.current = dir;

  var bot = new CoreBot();
  var handler = new PluginHandler(bot);

  handler.init().then((_) {
    bot.start();
  });
  return bot;
}
