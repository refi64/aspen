import 'package:ansicolor/ansicolor.dart';

import 'dart:io';

AnsiPen _errorPen = new AnsiPen()..red(),
        _warnPen = new AnsiPen()..magenta(),
        _notePen = new AnsiPen()..cyan();

/// Prints a note to the screen.
void note(String message) {
  print(_notePen(message));
}

/// Prints a warning message to the screen.
void warn(String message) {
  print(_warnPen(message));
}

/// Prints an error message to the screen, then exits.
void error(String message) {
  print(_errorPen(message));
  exit(1);
}

/// If [cond] is false, then prints [message] and exits.
void check(bool cond, String message) {
  if (!cond) {
    error(message);
  }
}
