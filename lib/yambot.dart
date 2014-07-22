library yambot;

import 'dart:collection';
import 'dart:async';
import 'dart:io';

import "package:irc/irc.dart" as IRC;
import 'package:plugins/loader.dart';
import 'package:yaml/yaml.dart';

part 'src/plugins/manager.dart';
part 'src/config.dart';
part 'src/core.dart';
part 'src/auth.dart';
part 'src/bot.dart';

/**
 * Launches the bot. The [path] will override the current [Directory]
 * and read all configurations from it.
 * Returns [YamBot].
 */
YamBot launchYamBot(String path) {
  var dir = new Directory(path).absolute;
  if (!dir.existsSync()) {
    throw new Exception("'$path' does not exist");
  }
  Directory.current = dir;

  var bot = new YamBot();
  var handler = new PluginHandler(bot);

  bot.init();
  handler.initListeners();

  handler.init().then((_) {
    bot.start();
  });
  return bot;
}
