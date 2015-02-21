library polymorphic.bot;

import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:profiler';

import 'package:yaml/yaml.dart' as yaml;
import 'package:irc/client.dart' as IRC;
import 'package:plugins/loader.dart';
import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:path/path.dart' as path;
import 'package:usage/usage_io.dart';

import 'package:quiver/async.dart';

import 'api.dart' as Polymorphic;

import "utils.dart";
import "slack.dart";

part 'src/plugins/handler.dart';
part 'src/plugins/communicator.dart';
part 'src/config.dart';
part 'src/core.dart';
part 'src/auth.dart';
part 'src/bot.dart';

class Globals {
  static List<String> EXTENSIONS = ["core", "polymorphic"];
  static PluginHandler pluginHandler;
  static Function kill;
  static String key;
  static Analytics analytics;
  static Map<String, dynamic> pubspec = _loadPubspec();
  static String version = _getVersion();
  
  static String _getVersion() {
    var v = new String.fromEnvironment("version");
    if (v != null) {
      return v;
    } else {
      return pubspec["version"];
    }
  }
  
  static List<String> getDependencyNames() {
    return pubspec["dependencies"].keys.toList();
  }
  
  static Map<String, dynamic> _loadPubspec() {
    var file = EnvironmentUtils.getPubSpecFile();
    if (!file.existsSync()) {
      return <String, dynamic>{
        "version": "Unknown",
        "dependencies": {}
      };
    } else {
      return yaml.loadYaml(file.readAsStringSync());
    }
  }
}

Random random = new Random();

String generateToken(int length) {
  var r = new Random(random.nextInt(5000));
  var buffer = new StringBuffer();
  for (int i = 1; i <= length; i++) {
    if (r.nextBool()) {
      String letter = alphabet[r.nextInt(alphabet.length)];
      buffer.write(r.nextBool() ? letter.toLowerCase() : letter);
    } else {
      buffer.write(numbers[r.nextInt(numbers.length)]);
    }
  }
  return buffer.toString();
}

/**
 * Launches the bot. The [path] will override the current [Directory]
 * and read all configurations from it.
 * Returns [CoreBot].
 */
CoreBot launchBot(String path) {
  var pubspecFile = EnvironmentUtils.getPubSpecFile();
  if (pubspecFile.existsSync()) {
    Globals.pubspec = yaml.loadYaml(pubspecFile.readAsStringSync());
  }
  
  var keyFile = new File("${Platform.environment['HOME']}/.polymorphic/key");

  if (!keyFile.existsSync()) {
    var key = generateToken(50);
    keyFile.createSync(recursive: true);
    print("[Polymorphic] Key Generated: ${key}");
    keyFile.writeAsStringSync(key);
  }

  Globals.key = keyFile.readAsStringSync().trim();

  BotMetrics.init();

  var dir = new Directory(path).absolute;

  if (!dir.existsSync()) {
    throw new Exception("'$path' does not exist");
  }

  var isShuttingDown = false;

  Directory.current = dir;

  var bot = new CoreBot();
  var analytics = Globals.analytics = new AnalyticsIO("UA-40996230-2", "PolymorphicBot", Globals.version);
  analytics.optIn = true;
  
  analytics.sendScreenView("initial start");
  
  var handler = Globals.pluginHandler = new PluginHandler(bot);

  var started = false;
  
  Globals.kill = ([_]) {
    if (!isShuttingDown) {
      isShuttingDown = true;
      
      print("Shutting Down");
      
      if (!started) {
        exit(0);
      }

      new Timer(new Duration(seconds: 4), () {
        exit(0);
      });

      handler.killPlugins().then((_) {
        bot.bots.forEach((it) {
          var b = bot[it];

          var timer = new Timer(new Duration(seconds: 2), () {
            if (b.client.connected) {
              b.client.disconnect(reason: "Stopping Bot");
            }
          });

          if (b.client != null) {
            var timer = new Timer(new Duration(seconds: 2), () {
              if (b.client.connected) {
                b.client.disconnect(reason: "Stopping Bot");
              }
            });

            b.client.send("QUIT :Stopping Bot");
          }
        });
      });
    }
  };

  [ProcessSignal.SIGINT].forEach((ProcessSignal signal) {
    signal.watch().listen(Globals.kill);
  });

  var stopwatch = new Stopwatch();
  stopwatch.start();
  handler.init().then((_) {
    stopwatch.stop();
    
    analytics.sendTiming("initial plugin load", stopwatch.elapsedMilliseconds);
    
    bot.start();
    started = true;
    analytics.sendScreenView("bot");
  });

  return bot;
}

const List<String> alphabet = const [
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z"
];

const List<int> numbers = const [
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9
];

const List<String> specials = const [
  "@",
  "=",
  "_",
  "+",
  "-",
  "!",
  "."
];