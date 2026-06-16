class ApiEndpoints {
  static const String baseUrl = 'https://iguana-smugly-phosphate.ngrok-free.dev/api';
  static const String baseStorage = 'https://iguana-smugly-phosphate.ngrok-free.dev/storage';
  static const String basePayment = "https://tucking-grope-angelic.ngrok-free.dev/api";

  static final Uri _baseUri = Uri.parse(baseUrl);
  
  static String get pusherHost => '10.0.2.2';
  static int get pusherPort => 8080;
  static String get pusherScheme => 'ws';

  static const String register = '$baseUrl/register';
  static const String registerOtp = '$baseUrl/register/otp';
  static const String registerResendOtp = '$baseUrl/register/resend-otp';
  static const String login = '$baseUrl/login';
  static const String user = '$baseUrl/user';
  static const String logout = '$baseUrl/logout';
  static const String menus = '$baseUrl/menus';
  static const String categories = '$baseUrl/categories';
  static const String galleries = '$baseUrl/galleries';
  static const String updateProfile = '$baseUrl/user/update';
  static const String verifyProfileOtp = '$baseUrl/user/update/verify-otp';
  static const String resendProfileOtp = '$baseUrl/user/update/resend-otp';
  static const String updatePassword = '$baseUrl/user/password';
  static const String orders = '$baseUrl/orders';
  static const String notifications = '$baseUrl/notifications';
  static const String reviews = '$baseUrl/reviews';
  static String reviewOrder(int id) => '$baseUrl/orders/$id/review';

  static String menuReviews(int id) => '$baseUrl/menus/$id/reviews';
  static String orderMessages(int id) => '$baseUrl/orders/$id/messages';
  static String deleteOrderMessage(int orderId, int messageId) => '$baseUrl/orders/$orderId/messages/$messageId';
  static String deliveryMessages(int id) => '$baseUrl/orders/$id/delivery-messages';
  static String deleteDeliveryMessage(int orderId, int messageId) => '$baseUrl/orders/$orderId/delivery-messages/$messageId';

  static const String unreadChatCount = '$baseUrl/messages/unread-count';
  static const String adminStats = '$baseUrl/admin/stats';
  static const String adminInbox = '$baseUrl/admin/inbox';
  static const String forgotPassword = '$baseUrl/password/forgot';
  static const String resetPassword = '$baseUrl/password/reset';
  static const String payments = "$basePayment/payments";
  
  // Driver Endpoints
  static const String driverOrders = '$baseUrl/driver/orders';
  static const String driverInbox = '$baseUrl/driver/inbox';
  static String driverUpdateStatus(int id) => '$baseUrl/driver/orders/$id/status';
}
