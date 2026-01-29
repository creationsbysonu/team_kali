/// Stub implementation for non-web platforms.
/// Browser history manipulation is only available on web.
library;

/// Replace browser history state to prevent back navigation.
/// No-op on non-web platforms.
void replaceHistoryState(String path, String title) {
  // No-op for non-web platforms
}

/// Clear browser history by replacing current state.
/// No-op on non-web platforms.
void clearBrowserHistory(String path, String title) {
  // No-op for non-web platforms
}
