import 'package:polymorphic_bot/bot.dart';
import 'package:irc/client.dart' as IRC;

import "common.dart";
export "common.dart";

Map<String, dynamic> perms = {
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

Map<String, dynamic> groups = {
  "public": [
    "pub.command"
  ],
  "regular": [
    "reg.command"
  ]
};

String network = "TestNet";
BotMock bot = new BotMock(network, perms, groups);
Auth auth = new Auth(network, bot);

@Group("permissions")
class PermissionTests {
  @Test("guest authenticated")
  guestAuthenticated() => auth.registeredAs("guest").then((info) {
    expect(info[0], equals("guest"));
  });
}

void main() {
  group("permissions", () {
    _guestTest(auth);
    _userTest(auth);
  });
}

void _guestTest(Auth auth) {
  String nick = "guest";

  test("$nick authenticated", () {
    return auth.registeredAs(nick).then((List info) {
      expect(info[0], equals(nick));
    });
  });

  group("$nick node:", () {
    test("pub.command", () {
      return auth.hasPermission("pub", nick, "command").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("core.test", () {
      return auth.hasPermission("core", nick, "test").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("something.test", () {
      return auth.hasPermission("something", nick, "test").then((bool val) {
        expect(val, isFalse, reason: "$nick should not have permission");
      });
    });

    test("reg.command", () {
      return auth.hasPermission("reg", nick, "command").then((bool val) {
        expect(val, isFalse, reason: "$nick should not have permission");
      });
    });
  });
}

void _userTest(Auth auth) {
  String nick = "user";

  test("$nick authenticated", () {
    return auth.registeredAs(nick).then((List info) {
      expect(info[0], equals(nick));
    });
  });

  group("$nick node:", () {
    test("pub.command", () {
      return auth.hasPermission("pub", nick, "command").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("something.test", () {
      return auth.hasPermission("something", "user", "test").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("something.test.node", () {
      return auth.hasPermission("something", "user", "test.node").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("reg.command", () {
      return auth.hasPermission("reg", "user", "command").then((bool val) {
        expect(val, isTrue, reason: "$nick should have permission");
      });
    });

    test("-core.test", () {
      return auth.hasPermission("core", "user", "test").then((bool val) {
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
    _mockClient = new ClientMock(new IRC.IrcConfig());
  }

}

class ClientMock extends IRC.Client {

  bool _sent = false;

  @override
  List<IRC.Channel> channels = [new IRC.Channel(null, "#demo")];

  ClientMock(IRC.IrcConfig config) : super(config);

  @override
  void send(String line) {
    var who = line.split(" ")[1];
    var builder = new IRC.WhoisBuilder("${who}nick");
    builder.username = who;
    builder.channels = ["#demo"];
    post(new IRC.WhoisEvent(null, builder));
  }
}
