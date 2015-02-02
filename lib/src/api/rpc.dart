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

const Object _UNSPECIFIED = const Object();

void _addPluginMethod(Plugin plugin, LibraryMirror lib, MethodMirror mirror) {
  var isVoid = mirror.returnType == currentMirrorSystem().voidType;

  plugin.addRemoteMethod(MirrorSystem.getName(mirror.simpleName), (call) {
    var params = mirror.parameters;
    var positional = [];
    var named = {};

    if (params.length == 1 && params.first.type.reflectedType != Map) {
      var val = call.getArgument("value", defaultValue: _UNSPECIFIED);
      if (val != _UNSPECIFIED) {
        positional.add(val);
      } else {
        throw new PluginException("Parameter 'value' is required.");
      }
    } else {
      params.forEach((it) {
        var n = MirrorSystem.getName(it.simpleName);
        if (call.getArgument(n, defaultValue: _UNSPECIFIED) != _UNSPECIFIED) {
          if (it.isNamed) {
            named[n] = call.getArgument(n);
          } else {
            positional.add(call.getArgument(n));
          }
        } else {
          if (!it.isOptional && !it.isNamed) {
            throw new PluginException("Parameter '${n}' is required.");
          }
        }
      });
    }

    if (isVoid) {
      lib.invoke(mirror.simpleName, positional, named);
    } else {
      var result = new Future.value(lib.invoke(mirror.simpleName, positional, named).reflectee);
      result.then(call.reply);
    }
  });
}

class RemoteMethodInfo {
  final String name;
  final bool isVoid;
  final Map<String, dynamic> metadata;

  RemoteMethodInfo(this.name, {this.metadata: const {}, this.isVoid: false});
}

@proxy
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
  
  Future noSuchMethod(Invocation invocation) {
    if (!invocation.isAccessor) {
      var name = MirrorSystem.getName(invocation.memberName);
      var params = invocation.positionalArguments;
      var n = invocation.namedArguments;
      
      if (params.isEmpty && n.isNotEmpty) {
        return myPlugin.callRemoteMethod(pluginName, name, n);
      } else {
        return myPlugin.callRemoteMethod(pluginName, name, params.isEmpty ? null : params.first); 
      }
    } else {
      super.noSuchMethod(invocation);
      return null;
    }
  }
}
