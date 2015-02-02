part of polymorphic.slack;

class SlackError {
  final String type;
  
  SlackError(this.type);
  
  @override
  String toString() => "SlackError(${type})";
}