class Message {
  final String id;
  final String text;
  final DateTime time;
  final bool fromMe;
  bool read;

  Message({
    required this.id,
    required this.text,
    required this.time,
    required this.fromMe,
    this.read = false,
  });
}
