import 'dart:async';

class ActiveTimerState {
  final int chatId;
  final int messageId;
  final String title;
  final DateTime endDateTime;
  Timer? timer;

  ActiveTimerState({
    required this.chatId,
    required this.messageId,
    required this.title,
    required this.endDateTime,
    this.timer,
  });
}
