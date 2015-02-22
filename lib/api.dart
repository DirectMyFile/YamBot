/**
 * # PolymorphicBot API
 *
 * This is the API for PolymorphicBot.
 *
 * ## Plugin Structure
 *
 * Plugins are loaded from the directory `plugins/`. Each directory is a plugin which has a pubspec.yaml and a main file.
 *
 * ### pubspec.yaml
 *
 * ```yaml
 * name: MyPlugin
 * dependencies:
 *   polymorphic_bot: any
 * ```
 *
 * ### main.dart
 *
 * ```dart
 * import "package:polymorphic_bot/api.dart";
 *
 * @PluginInstance()
 * Plugin plugin;
 *
 * @BotInstance()
 * BotConnector bot;
 *
 * main(args, port) => polymorphic(args, port);
 *
 * @Command("hello")
 * hello(CommandEvent event) => event.reply("> Hello World");
 * ```
 */
library polymorphic.api;

import "dart:async";
import "dart:convert";
import "dart:isolate";
import "dart:io";
import "dart:mirrors";
import "dart:math";

import "package:plugins/plugin.dart";
import "package:http/http.dart" as http;
import "package:polymorphic_bot/utils.dart";

import "package:irc/client.dart" show Color;
import "package:html5lib/parser.dart" as htmlParser show parse;
import "package:jsonx/jsonx.dart" as jsonx;
import "package:collection/wrappers.dart" show DelegatingList, DelegatingMap;
import "package:html5lib/dom.dart" as html;

import "package:yaml/yaml.dart" as yaml;

import "package:quiver/core.dart";
import "package:quiver/async.dart";
import "package:quiver/pattern.dart";

export "package:polymorphic_bot/utils.dart";

part "src/api/core.dart";
part "src/api/events.dart";
part "src/api/commands.dart";
part "src/api/storage.dart";
part "src/api/http.dart";
part "src/api/rpc.dart";
part "src/api/channel.dart";
part "src/api/metadata.dart";
part "src/api/helpers.dart";

bool _createdPlugin = false;
BotConnector _bot;