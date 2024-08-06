import 'dart:developer' as developer;

class Logger {
  final String name;

  Logger(this.name);

  void _log(String level, String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      '[$level] $message',
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }
  factory Logger.forClass(Type type) {
    return Logger(type.toString());
  }
  void info(String message, [List<Object>? args]) {
    _log('INFO', _format(message, args));
  }
  void debug(String message, [List<Object>? args]) {
    _log('DEBUG', _format(message, args));
  }
  void warn(String message, [List<Object>? args]) {
    _log('WARN', _format(message, args));
  }

  void err(String message, [List<Object>? args]) {
    _log('ERROR', _format(message, args));
  }

  String _format(String message, [List<Object>? args]) {
    if (args == null || args.isEmpty) {
      return message;
    }
    for (var arg in args) {
      message = message.replaceFirst(RegExp(r'\{\}'), arg.toString() ?? 'null');
    }
    return message;
  }
}
