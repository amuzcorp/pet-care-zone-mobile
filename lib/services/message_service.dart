import 'dart:async';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;

  MessageService._internal();

  final StreamController<String> messageController = StreamController<String>.broadcast();

  void addMessage(String message) {
    if (!messageController.isClosed) {
      messageController.add(message);
    }
  }

  void dispose() {
    messageController.close();
  }
}
