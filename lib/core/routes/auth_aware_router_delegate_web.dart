// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Replace browser history state to prevent back navigation.
/// This replaces the current history entry instead of pushing a new one.
void replaceHistoryState(String path, String title) {
  html.window.history.replaceState(null, title, path);
}

/// Clear browser history by replacing current state.
/// This effectively prevents the user from navigating back to previous pages.
void clearBrowserHistory(String path, String title) {
  // Replace the current history state
  html.window.history.replaceState(null, title, path);
}
