library polymorphic.bot;

import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:profiler';

import 'package:yaml/yaml.dart' as yaml;
import 'package:irc/client.dart' as IRC;
import 'package:plugins/loader.dart';
import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:path/path.dart' as path;

import 'package:quiver/async.dart';

import 'api.dart' as Polymorphic;

import "utils.dart";

part 'src/plugins/handler.dart';
part 'src/plugins/communicator.dart';
part 'src/config.dart';
part 'src/core.dart';
part 'src/auth.dart';
part 'src/bot.dart';

class Globals {
  static List<String> EXTENSIONS = ["core", "polymorphic"];
  static PluginHandler pluginHandler;
}

/**
 * Launches the bot. The [path] will override the current [Directory]
 * and read all configurations from it.
 * Returns [CoreBot].
 */
CoreBot launchBot(String path) {
  BotMetrics.init();
  
  var dir = new Directory(path).absolute;
  
  if (!dir.existsSync()) {
    throw new Exception("'$path' does not exist");
  }
  
  var isShuttingDown = false;
  
  Directory.current = dir;

  var bot = new CoreBot();
  var handler = Globals.pluginHandler = new PluginHandler(bot);
  
  [ProcessSignal.SIGINT].forEach((ProcessSignal signal) {
    signal.watch().listen((data) {
      if (!isShuttingDown) {
        isShuttingDown = true;
        print("Shutting Down");
        handler.killPlugins();
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
