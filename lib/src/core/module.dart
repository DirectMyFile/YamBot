part of yambot.core;

abstract class Module {
  /**
   * Module Name
   */
  String get name;

  /**
   * Initializes this Module
   */
  void init(YamBot bot);

  /**
   * Applies the Module to the IRC Client
   */
  void apply(IRC.Client client);
}

class CoreModule extends Module {
  YamBot bot;

  String name = "Core";

  @override
  void init(YamBot bot) {
    this.bot = bot;
  }

  @override
  void apply(IRC.Client client) {
    client.register((IRC.ReadyEvent event) {
      bot.config.channels.forEach(event.join);
    });
  }
}