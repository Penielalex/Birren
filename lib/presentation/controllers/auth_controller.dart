import 'package:get/get.dart';

import '../../data/service/shared_prefs_service.dart';

import '../../data/db/user_dao.dart';
import '../../app/user_usecases.dart';
import '../../domain/entities/user.dart';
import 'package:logger/logger.dart';

class AuthController extends GetxController {
  final SharedPrefsService prefs;
  final GetUsersUseCase getUsers;
  final AddUserUseCase addUser;

  AuthController({
    required this.getUsers,
    required this.addUser,
    required this.prefs

  });
  var isLoading = false.obs;
  var loginType = ''.obs;
  var users = <User>[].obs;
  var logger = Logger();



  Future<void> initAuth() async {
    logger.i("auth controller initialized");
    // Load stored login type
    isLoading.value=true;
    final type = await prefs.getLoginType();
    final id = await prefs.getId();
    final googleId = await prefs.getGoogleId();
    loginType.value = type ?? '';
    if (loginType.value == 'guest') {
      users.value = await getUsers.execute();

      if(id == null){
        await prefs.setLoginType('guest', users.first.id.toString(),users.first.googleId ?? "" );
      }

    }
    isLoading.value=false;
  }

  Future<void> loginAsGuest(String name) async {
    try{
    final now =DateTime.now();
    final user = User(
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await addUser.execute(user);
    }finally{
      users.value = await getUsers.execute();
      await prefs.setLoginType('guest', users.first.id.toString(),users.first.googleId ?? "" );
      loginType.value = 'guest';

    }





    // Save guest in local DB

  }

  Future<void> loginWithGoogle() async {
    logger.i("google in controller");
  }

  Future<void> logout() async {
    await prefs.clearAll();
    //google logout here
    loginType.value = '';
    users.value = <User>[].obs;
  }
}
