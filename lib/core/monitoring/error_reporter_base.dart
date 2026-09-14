abstract interface class ErrorReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  });
}
