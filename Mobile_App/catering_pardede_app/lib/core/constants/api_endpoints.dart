class ApiEndpoints {
  static const String baseUrl = 'https://iguana-smugly-phosphate.ngrok-free.dev/api';
  static const String baseStorage = 'https://iguana-smugly-phosphate.ngrok-free.dev/storage';
  static const String basePayment = "https://tucking-grope-angelic.ngrok-free.dev/api";

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
  static const String reviews = '$baseUrl/reviews';
  static String reviewOrder(int id) => '$baseUrl/orders/$id/review';
  static String menuReviews(int id) => '$baseUrl/menus/$id/reviews';
  static String orderMessages(int id) => '$baseUrl/orders/$id/messages';
  static const String adminStats = '$baseUrl/admin/stats';
  static const String adminInbox = '$baseUrl/admin/inbox';
  static const String forgotPassword = '$baseUrl/password/forgot';
  static const String resetPassword = '$baseUrl/password/reset';
  static const String payments = "$basePayment/payments";
  
  // Driver Endpoints
  static const String driverOrders = '$baseUrl/driver/orders';
  static const String driverLocation = '$baseUrl/driver/location';
  static String driverUpdateStatus(int id) => '$baseUrl/driver/orders/$id/status';
}
