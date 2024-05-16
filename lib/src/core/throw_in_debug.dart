void throwInDebug(Object error) {
  assert(() {
    throw error;
  }());
}
