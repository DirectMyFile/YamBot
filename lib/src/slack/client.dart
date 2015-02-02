part of polymorphic.slack;

class SlackClient {
  final String token;
  
  SlackClient(this.token);
  
  Future<Map<String, dynamic>> sendRequest(String method, {Map<String, dynamic> parameters: const {}}) {
    var url = "https://slack.com/api/${method}?token=${token}";
    
    var p = new Map.from(parameters);
    
    return http.post(url, body: JSON.encode(p)).then((response) {
      if (response.statusCode != 200) {
        throw new Exception("ERROR");
      }
      var json = JSON.decode(response.body);
      if (!json["ok"]) {
        throw new SlackError(json["error"]);
      }
      return json;
    });
  }

  Future<WebSocket> _createWebSocket() {
    return sendRequest("rtm.start").then((response) {
      return WebSocket.connect(response["url"]);
    });
  }
  
  Future<SlackBot> createBot() {
    return _createWebSocket().then((socket) {
      return new SlackBot(socket);
    });
  }
  
  Future<Map<String, dynamic>> getChannelInfo(String id) {
    return sendRequest("channels.info", parameters: {
      "channel": id
    }).then((response) {
      return response["channel"];
    });
  }
  
  Future<List<Map<String, dynamic>>> getChannels() {
    return sendRequest("channels.list").then((response) {
      return response["channels"];
    });
  }
  
  Future<Map<String, dynamic>> getUserInfo(String id) {
    return sendRequest("users.info", parameters: {
      "user": id
    }).then((response) {
      return response["user"];
    });
  }
  
  Future<String> getChannelName(String id) => getChannelInfo(id).then((it) => it["name"]);
  Future<String> getUserName(String id) => getUserInfo(id).then((it) => it["name"]);
  
  Future<bool> setChannelTopic(String id, String topic) {
    return sendRequest("channels.setTopic", parameters: {
      "channel": id,
      "topic": topic
    }).then((response) {
      return true;
    });
  }
  
  Future<String> lookupChannelId(String name) {
    return getChannels().then((channels) {
      return channels.where((it) => it["name"] == name || it["name"] == name.substring(1)).first["id"];
    });
  }
  
  Future<Map<String, dynamic>> joinChannel(String name) {
    return sendRequest("channels.join", parameters: {
      "name": name
    }).then((data) {
      return data["channel"];
    });
  }
  
  Future leaveChannel(String id) {
    return sendRequest("channels.join", parameters: {
      "channel": id
    });
  }
  
  Future<bool> setChannelPurpose(String id, String purpose) {
    return sendRequest("channels.setTopic", parameters: {
      "channel": id,
      "purpose": purpose
    }).then((response) {
      return true;
    });
  }
}