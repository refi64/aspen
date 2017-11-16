import 'package:ansicolor/ansicolor.dart';

import 'dart:io';

AnsiPen _errorPen = new AnsiPen()..red(),
        _warnPen = new AnsiPen()..magenta(),
        _notePen = new AnsiPen()..cyan();

void note(String message) {
  print(_notePen(message));
}

void warn(String message) {
  print(_warnPen(message));
}

void error(String message) {
  print(_errorPen(message));
  exit(1);
}

void check(bool cond, String message) {
  if (!cond) {
    error(message);
  }
}
