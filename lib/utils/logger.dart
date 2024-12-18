import 'package:logger/logger.dart';

final logD = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // number of method calls to be displayed
    errorMethodCount: 8, // number of method calls if stacktrace is provided
    lineLength: 120, // width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    dateTimeFormat: DateTimeFormat.dateAndTime, // Should each log print contain a timestamp
  ),
);
