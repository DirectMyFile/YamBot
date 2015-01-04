part of polymorphic.api;

typedef void RemoteCallHandler(RemoteCall call);

class RemoteCall {
  final Request request;
  
  RemoteCall(this.request);
  
  dynamic getArgument(String name, {dynamic defaultValue}) => request.data.containsKey(name) ? request.data[name] : defaultValue;
  
  void reply(dynamic value) => request.reply({
    "value": value
  });
  
  void replyMap(Map<String, dynamic> map) => request.reply(map);
}

class RemoteMethod {
  final String name;
  final bool isVoid;
  final Map<String, dynamic> metadata;
  
  RemoteMethod(this.name, {this.metadata: const {}, this.isVoid: false});
}