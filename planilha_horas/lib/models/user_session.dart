class UserSession {
  static String? token;
  static int? userId;
  static String? email;

  static void clear() {
    token = null;
    userId = null;
    email = null;
  }

  static bool get isLoggedIn => token != null;
}
