# Polymorphic Bot

Automation Bot that connects to IRC or Slack.

## Goals

- Provide Tools for Automation
- Provide Plugin System
- Be Simple and Elegant
- Work for the User

## Features

- Simple but very powerful plugin system
- Designed for Multi-Network Bots
- Very Fast

## Plugin System

### Features

- Built-in HTTP Server that plugins can use
- Simple API
- Flexible and Powerful
- Asynchronous by Design

### Example

Simple Plugin with a hello command:

```dart
import "package:polymorphic_bot/plugin.dart";
export "package:polymorphic_bot/plugin.dart";

@PluginInstance()
Plugin plugin;

@BotInstance()
BotConnector bot;

@Command("hello")
hello(CommandEvent event) => event.reply("> Hello World");
```
