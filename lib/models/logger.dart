import 'dart:developer' as developer;
import 'package:intl/intl.dart'; // For formatting the timestamp

class Logger {
  final String name;

  Logger(this.name);

  void _log(String level, String message, {Object? error, StackTrace? stackTrace}) {
    // Get the current time formatted as hour:minute:second
    String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

    // Include the time in the log message
    developer.log(
      '[$currentTime] [$level] $message',
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  factory Logger.forClass(Type type) {
    return Logger(type.toString());
  }

  void info(String message, [List<Object?>? args]) { // Allow nullable arguments
    _log('INFO', _format(message, args));
  }

  void debug(String message, [List<Object?>? args]) {
    _log('DEBUG', _format(message, args));
  }

  void warn(String message, [List<Object?>? args]) {
    _log('WARN', _format(message, args));
  }

  void err(String message, [List<Object?>? args]) {
    _log('ERROR', _format(message, args));
  }

  String _format(String message, [List<Object?>? args]) {
    if (args == null || args.isEmpty) {
      return message;
    }
    for (var arg in args) {
      // Replace '{}' with the string representation of the argument or 'null'
      message = message.replaceFirst(RegExp(r'\{\}'), arg?.toString() ?? 'null');
    }
    return message;
  }
}
