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
        
        new Timer(new Duration(seconds: 10), () {
          exit(0);
        });
        
        handler.killPlugins().then((_) {
          bot.bots.forEach((it) {
            var b = bot[it];
            
            var timer = new Timer(new Duration(seconds: 5), () {
              if (b.client.connected) {
                b.client.disconnect(reason: "Stopping Bot");
              }
            });
            
            if (b.client != null) {
              var timer = new Timer(new Duration(seconds: 5), () {
                if (b.client.connected) {
                  b.client.disconnect(reason: "Stopping Bot");
                }
              });
              
              b.client.send("QUIT :Stopping Bot");
            }
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
