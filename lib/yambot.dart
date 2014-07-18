library yambot;

import 'dart:io';

import "package:irc/irc.dart" as IRC;
import 'package:yaml/yaml.dart';

part 'src/config.dart';
part 'src/core.dart';

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
  bot.start();
  return bot;
}
