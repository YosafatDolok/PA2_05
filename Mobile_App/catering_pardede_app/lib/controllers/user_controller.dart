import '/core/services/auth_service.dart';
import '/models/user_model.dart';

class UserController {
  static Future<UserModel?> fetchUser() async {
    final data = await AuthService.getUser();

    if (data == null) return null;

    return UserModel.fromJson(data);
  }
}
