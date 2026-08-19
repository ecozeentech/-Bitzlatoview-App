class SessionHelpers {
  static bool shouldPersistSession(String? url) {
    if (url == null || url.isEmpty) return false;

    final path = Uri.parse(url).path.toLowerCase();
    const authPaths = [
      '/login',
      '/register',
      '/password',
      '/forgot-password',
      '/reset-password',
    ];

    return !authPaths.any(path.contains);
  }
}
