class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String user = '$baseUrl/user';
  static const String logout = '$baseUrl/logout';
  static const String menus = '$baseUrl/menus';
  static const String categories = '$baseUrl/categories';
  static const String galleries = '$baseUrl/galleries';
  static const String updateProfile = '$baseUrl/user/update';
  static const String orders = '$baseUrl/orders';
  static const String notifications = '$baseUrl/notifications';
}
