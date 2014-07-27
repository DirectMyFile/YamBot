import 'package:scheduled_test/scheduled_test.dart';

import 'package:polymorphic_bot/bot.dart';
import 'package:irc/irc.dart' as IRC;

void main() {
  var perms = {
    "*": [
      "core.test",
      "something.test.node"
    ],
    "user": [
      "-core.test",
      "something.test"
    ]
  };

  var network = "TestNet";
  var bot = new BotMock(network, perms);
  var auth = new Auth(network, bot);

  group("permissions", () {
    test("user authenticated", () {
      wrapFuture(auth.registeredAs("user").then((List info) {
        expect(info[0], equals("user"));
      }));
    });

    test("guest authenticated", () {
      wrapFuture(auth.registeredAs("guest").then((List info) {
        expect(info[0], equals("guest"));
      }));
    });

    test("guest nodes", () {
      String nick = "guest";
      auth.hasPermission("core", nick, "test").then((bool val) {
        expect(val, isTrue, reason: "Guest doesn't have permission to node 'core.test'");
      });
      auth.hasPermission("something", nick, "test").then((bool val) {
        expect(val, isFalse, reason: "Guest has permission to node 'something.test'");
      });
    });

    test("user nodes", () {
      String nick = "user";
      auth.hasPermission("something", nick, "test").then((bool val) {
        expect(val, isTrue, reason: "User doesn't have permission node 'something.test'");
      });
      auth.hasPermission("something", nick, "test.node").then((bool val) {
        expect(val, isTrue, reason: "User doesn't have permission node 'something.test.node'");
      });
      auth.hasPermission("core", nick, "test").then((bool val) {
        expect(val, isFalse, reason: "User has permission to a negated node '-core.test'");
      });
    });

  });
}

class BotMock extends Bot {

  @override
  IRC.Client get client => _mockClient == null ? super.client : _mockClient;
  IRC.Client _mockClient;

  BotMock(String network, Map perms) : super (network, {}, {}, {}, perms) {
    // Order sensitive in order to avoid an NPE
    _mockClient = new ClientMock(new IRC.BotConfig());
  }

}

class ClientMock extends IRC.Client {

  bool _sent = false;

  @override
  List<IRC.Channel> channels = [new IRC.Channel(null, "#demo")];

  ClientMock(IRC.BotConfig config) : super(config);

  @override
  void send(String line) {
    schedule(() {
      var who = line.split(" ")[1];
      var builder = new IRC.WhoisBuilder("${who}nick");
      builder.username = who;
      builder.channels = ["#demo"];
      post(new IRC.WhoisEvent(null, builder));
    });
  }
}
