library polymorphic.bot;

import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:yaml/yaml.dart' as yaml;
import 'package:irc/client.dart' as IRC;
import 'package:plugins/loader.dart';
import 'package:path/path.dart' as path;

import 'api.dart' as Polymorphic;

import "utils.dart";

part 'src/plugins/handler.dart';
part 'src/plugins/communicator.dart';
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
  
  var shutting_down = false;
  
  Directory.current = dir;

  var bot = new CoreBot();
  var handler = new PluginHandler(bot);
  
  [ProcessSignal.SIGINT].forEach((ProcessSignal signal) {
    signal.watch().listen((data) {
      if (!shutting_down) {
        shutting_down = true;
        print("Shutting Down");
        handler.pm.killAll();
        bot.bots.forEach((it) {
          bot._clients[it].client.disconnect(reason: "Stopping Bot").then((_) {
            exit(0);
          });
        });
      }
    });
  });

  handler.init().then((_) {
    bot.start();
  });
  
  return bot;
}
