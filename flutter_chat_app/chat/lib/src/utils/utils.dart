

void printOnlyInDebug(Object? content) {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  if (inDebugMode) {
    // ignore: avoid_print
    print("XDEBUG: $content");
  }
}

