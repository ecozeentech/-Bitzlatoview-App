import 'package:bitzlatoview_mobile/providers/webview_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WebViewProvider provider;

  setUp(() {
    provider = WebViewProvider();
  });

  test('starts in the idle state', () {
    expect(provider.status, WebViewLoadStatus.idle);
    expect(provider.isLoading, isFalse);
    expect(provider.hasError, isFalse);
  });

  test('startLoading transitions to loading, resets error/progress and notifies', () {
    var notified = 0;
    provider.addListener(() => notified++);

    provider.startLoading('https://app.bitzlatoview.com/dashboard');

    expect(provider.status, WebViewLoadStatus.loading);
    expect(provider.currentUrl, 'https://app.bitzlatoview.com/dashboard');
    expect(provider.progress, 0);
    expect(provider.errorMessage, isNull);
    expect(notified, 1);
  });

  test('updateProgress clamps to [0, 1]', () {
    provider.updateProgress(1.5);
    expect(provider.progress, 1);
    provider.updateProgress(-1);
    expect(provider.progress, 0);
    provider.updateProgress(0.42);
    expect(provider.progress, 0.42);
  });

  test('finishLoading marks the page loaded and remembers it has loaded once', () {
    provider.startLoading('https://app.bitzlatoview.com');
    provider.finishLoading('https://app.bitzlatoview.com');

    expect(provider.status, WebViewLoadStatus.loaded);
    expect(provider.progress, 1);
    expect(provider.hasLoadedOnce, isTrue);
  });

  test('setError transitions to the error state with a message', () {
    provider.setError('Timed out');
    expect(provider.status, WebViewLoadStatus.error);
    expect(provider.hasError, isTrue);
    expect(provider.errorMessage, 'Timed out');
  });

  test('hasLoadedOnce is sticky across a subsequent error', () {
    provider.startLoading('https://app.bitzlatoview.com');
    provider.finishLoading('https://app.bitzlatoview.com');
    provider.setError('Network dropped mid-navigation');

    expect(provider.hasLoadedOnce, isTrue);
    expect(provider.hasError, isTrue);
  });

  test('updateCanGoBack only notifies on actual changes', () {
    var notified = 0;
    provider.addListener(() => notified++);

    provider.updateCanGoBack(true);
    expect(notified, 1);
    provider.updateCanGoBack(true);
    expect(notified, 1, reason: 'no-op update should not notify again');
    provider.updateCanGoBack(false);
    expect(notified, 2);
  });

  test('reset returns to idle without losing hasLoadedOnce', () {
    provider.startLoading('https://app.bitzlatoview.com');
    provider.finishLoading('https://app.bitzlatoview.com');
    provider.reset();

    expect(provider.status, WebViewLoadStatus.idle);
    expect(provider.progress, 0);
    expect(provider.hasLoadedOnce, isTrue);
  });
}
