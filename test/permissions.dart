import 'package:scheduled_test/scheduled_test.dart';

import 'package:polymorphic_bot/bot.dart';
import 'package:irc/irc.dart' as IRC;

void main() {
  var perms = {
    "groups": {
      "*": [ "public" ],
      "user": [ "regular" ]
    },
    "nodes": {
      "*": [
        "core.test",
        "something.test.node"
      ],
      "user": [
        "-core.test",
        "something.test"
      ]
    }
  };

  var groups = {
    "public": [
      "pub.command"
    ],
    "regular": [
      "reg.command"
    ]
  };

  var network = "TestNet";
  var bot = new BotMock(network, perms, groups);
  var auth = new Auth(network, bot);

  group("permissions", () {
    _guestTest(auth);
    _userTest(auth);
  });
}

void _guestTest(Auth auth) {
  String nick = "guest";

  test("$nick authenticated", () {
    wrapFuture(auth.registeredAs(nick).then((List info) {
      expect(info[0], equals(nick));
    }));
  });

  group("$nick node:", () {
    test("pub.command", () {
      auth.hasPermission("pub", nick, "command").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("core.test", () {
      auth.hasPermission("core", nick, "test").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("something.test", () {
      auth.hasPermission("something", nick, "test").then((bool val) {
        expect(val, isFalse, reason: "$nick should not have permission");
      });
    });

    test("reg.command", () {
      auth.hasPermission("reg", nick, "command").then((bool val) {
        expect(val, isFalse, reason: "$nick should not have permission");
      });
    });
  });
}

void _userTest(Auth auth) {
  String nick = "user";

  test("$nick authenticated", () {
    wrapFuture(auth.registeredAs(nick).then((List info) {
      expect(info[0], equals(nick));
    }));
  });

  group("$nick node:", () {
    test("pub.command", () {
      auth.hasPermission("pub", nick, "command").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("something.test", () {
      auth.hasPermission("something", "user", "test").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("something.test.node", () {
      auth.hasPermission("something", "user", "test.node").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("reg.command", () {
      auth.hasPermission("reg", "user", "command").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("-core.test", () {
      auth.hasPermission("core", "user", "test").then((bool val) {
        expect(val, isFalse, reason: "$nick should not have permission");
      });
    });
  });
}

class BotMock extends Bot {

  @override
  IRC.Client get client => _mockClient == null ? super.client : _mockClient;
  IRC.Client _mockClient;

  BotMock(String network, Map perms, Map groups)
            : super (network, {}, {}, {}, perms, groups) {
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
