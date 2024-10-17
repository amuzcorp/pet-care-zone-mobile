import 'dart:async';

class MessageService {
  StreamController<String> messageController = StreamController<String>.broadcast();

  dispose() {
    messageController.close();
  }
}
