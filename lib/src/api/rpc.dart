part of polymorphic.api;

typedef void RemoteCallHandler(RemoteCall call);

class RemoteCall {
  final Request request;

  RemoteCall(this.request);

  dynamic getArgument(String name, {dynamic defaultValue}) {
    if (request.data == null || (!request.data.containsKey(name) && request.data["value"] is! Map)) {
      return defaultValue;
    }
    
    if (request.data.containsKey(name)) {
      return request.data[name];
    } else {
      return request.data["value"].containsKey(name) ? request.data["value"][name] : defaultValue;
    }
  }

  void reply(dynamic value) => request.reply({
    "value": value
  });
  
  void error(String message) => request.reply({
    "exception": {
      "message": message
    }
  });
}

class RemoteMethodInfo {
  final String name;
  final bool isVoid;
  final Map<String, dynamic> metadata;

  RemoteMethodInfo(this.name, {this.metadata: const {}, this.isVoid: false});
}

class PluginInterface {
  final Plugin myPlugin;
  final String pluginName;

  PluginInterface(this.myPlugin, this.pluginName);

  Future callMethod(String method, [dynamic arguments]) {
    return myPlugin.callRemoteMethod(pluginName, method, arguments);
  }

  Future<List<RemoteMethodInfo>> listMethods() {
    return myPlugin.getRemoteMethods(pluginName);
  }
}
