enum MessageStatus {
  pending('Pending'),
  sent('Sent'),
  delivered('Delivered'),
  seen('Seen');

  const MessageStatus(this.label);
  final String label;
}

class Message {
  const Message({
    required this.text,
    required this.time,
    required this.isMine,
    this.status = MessageStatus.sent,
  });

  final String text;
  final String time;
  final bool isMine;
  final MessageStatus status;
}
