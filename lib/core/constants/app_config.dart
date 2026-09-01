class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.jamendo.com/v3.0';

  static const String tracksEndpoint = '/tracks/';

  static const int pageSize = 20;

  static const String clientId = String.fromEnvironment('JAMENDO_CLIENT_ID');
}
