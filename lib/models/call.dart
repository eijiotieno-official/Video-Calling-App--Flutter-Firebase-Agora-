class CallModel {
  String? id;
  String channel;
  String caller;
  String called;
  bool? active;
  bool? accepted;
  bool? rejected;
  bool? connected;

  CallModel({
    required this.id,
    required this.channel,
    required this.caller,
    required this.called,
    required this.active,
    required this.accepted,
    required this.rejected,
    required this.connected,
  });
}
