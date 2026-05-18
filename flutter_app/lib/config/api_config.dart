class ApiConfig {
  // Change to your backend URL
  static const String baseUrl = 'http://localhost:5000/api';

  static const String authEndpoint = '/auth';
  static const String roomsEndpoint = '/rooms';
  static const String guestsEndpoint = '/guests';
  static const String checkinsEndpoint = '/checkins';
  static const String invoicesEndpoint = '/invoices';
  static const String staffEndpoint = '/staff';
  static const String dashboardEndpoint = '/dashboard';

  static String get loginUrl => '$baseUrl$authEndpoint/login';
  static String get meUrl => '$baseUrl$authEndpoint/me';
  static String get roomsUrl => '$baseUrl$roomsEndpoint';
  static String get guestsUrl => '$baseUrl$guestsEndpoint';
  static String get checkinsUrl => '$baseUrl$checkinsEndpoint';
  static String get invoicesUrl => '$baseUrl$invoicesEndpoint';
  static String get staffUrl => '$baseUrl$staffEndpoint';
  static String get dashboardStatsUrl => '$baseUrl$dashboardEndpoint/stats';
}
