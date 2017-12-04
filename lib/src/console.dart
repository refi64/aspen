import 'package:ansicolor/ansicolor.dart';

import 'dart:io';

AnsiPen _errorPen = new AnsiPen()..red(),
        _warnPen = new AnsiPen()..magenta(),
        _notePen = new AnsiPen()..cyan(),
        _successPen = new AnsiPen()..green();

void _write(String message, {bool newline}) {
  if (newline) {
    print(message);
  } else {
    stdout.write(message);
  }
}

/// Prints a note to the screen.
void note(String message, {bool newline: true}) {
  _write(_notePen(message), newline: newline);
}

/// Prints a success message to the screen.
void success(String message, {bool newline: true}) {
  _write(_successPen(message), newline: newline);
}

/// Prints a warning message to the screen.
void warn(String message, {bool newline: true}) {
  _write(_warnPen(message), newline: newline);
}

/// Prints an error message to the screen, then exits.
void error(String message, {bool newline: true}) {
  _write(_errorPen(message), newline: newline);
  exit(1);
}

/// If [cond] is false, then prints [message] and exits.
void check(bool cond, String message) {
  if (!cond) {
    error(message);
  }
}

/// Shows a message indicating the current progress.
void showProgress({int current, int total, String message}) {
  note('\r\x1B[K[$current/$total] $message...', newline: false);
}
