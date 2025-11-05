import 'package:birren/data/service/sms_service.dart';
import 'package:birren/presentation/controllers/auth_controller.dart';
import 'package:birren/presentation/pages/login_page.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/db/app_database.dart';
import 'data/db/user_dao.dart';
import 'data/db/bank_dao.dart';
import 'data/db/transaction_dao.dart';
import 'data/db/limit_dao.dart';
import 'data/repository_impl/user_repository_impl.dart';
import 'data/repository_impl/bank_repository_impl.dart';
import 'data/repository_impl/transaction_repository_impl.dart';
import 'data/repository_impl/limit_repository_impl.dart';
import 'app/user_usecases.dart';
import 'app/bank_usecases.dart';
import 'app/transaction_usecases.dart';
import 'app/limit_usecases.dart';
import 'presentation/controllers/user_controller.dart';
import 'presentation/controllers/bank_controller.dart';
import 'presentation/controllers/transaction_controller.dart';
import 'presentation/controllers/limit_controller.dart';
import 'data/service/shared_prefs_service.dart';
import 'presentation/pages/home_page.dart';
import 'data/api/user_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Database ---
  final db = AppDatabase();

  // --- User Setup ---
  final userDao = UserDao(db);
  final userApi = UserApi();
  final userRepository = UserRepositoryImpl(api: userApi, dao: userDao);

  final getUsersUseCase = GetUsersUseCase(userRepository);
  final addUserUseCase = AddUserUseCase(userRepository);
  final updateUserUseCase = UpdateUserUseCase(userRepository);
  final deleteUserUseCase = DeleteUserUseCase(userRepository);

  Get.put(UserController(
    getUsers: getUsersUseCase,
    addUser: addUserUseCase,
    updateUser: updateUserUseCase,
    deleteUser: deleteUserUseCase,
  ));

  // --- Auth Controller ---
  final prefs = SharedPrefsService();
  final smsServices = SmsService();
  final authController = AuthController(
    prefs: prefs,
    getUsers: getUsersUseCase,
    addUser: addUserUseCase,
  );
  Get.put(authController);
  await authController.initAuth();

  final transactionDao = TransactionDao(db);
  final transactionRepository = TransactionRepositoryImpl(dao: transactionDao);

  final addTransactionUseCase = CreateTransactionUseCase(transactionRepository);
  final deleteTransactionWithBankIDUseCase = DeleteTransactionWithBankIdUseCase(transactionRepository);


  // --- Bank Setup ---
  final bankDao = BankDao(db);
  final bankRepository = BankRepositoryImpl(dao: bankDao);

  final getBanksUseCase = GetBanksUseCase(bankRepository);
  final getBanksByUserUseCase = GetBanksByUserUseCase(bankRepository);
  final addBankUseCase = AddBankUseCase(bankRepository);
  final updateBankUseCase = UpdateBankUseCase(bankRepository);
  final deleteBankUseCase = DeleteBankUseCase(bankRepository);

  final bankController = BankController(
    smsService: smsServices,
    prefs: prefs,
    getBanksUseCase: getBanksUseCase,
    getBanksByUserUseCase: getBanksByUserUseCase,
    addBankUseCase: addBankUseCase,
    updateBankUseCase: updateBankUseCase,
    deleteBankUseCase: deleteBankUseCase,
    createTransactionUseCase: addTransactionUseCase,
    deleteTransactionWithBankIdUseCase: deleteTransactionWithBankIDUseCase
  );
  Get.put(bankController);

  // --- Transaction Setup ---


  final getTransactionsUseCase = GetAllTransactionsUseCase(transactionRepository);
  final getTransactionsByBankUseCase = GetTransactionsByBankIdUseCase(transactionRepository);

  final updateTransactionUseCase = UpdateTransactionUseCase(transactionRepository);
  final deleteTransactionUseCase = DeleteTransactionUseCase(transactionRepository);

  final transactionController = TransactionController(
    prefs: prefs,
    getAllTransactionsUseCase: getTransactionsUseCase,
    createTransactionUseCase: addTransactionUseCase,
    updateTransactionUseCase: updateTransactionUseCase,
    deleteTransactionUseCase: deleteTransactionUseCase,
    getBanksUseCase: getBanksUseCase,
    smsService: smsServices,
    updateBankUseCase: updateBankUseCase
  );
  Get.put(transactionController);

  // --- Limit Setup ---
  final limitDao = LimitDao(db);
  final limitRepository = LimitRepositoryImpl(dao: limitDao);

  final getLimitsUseCase = GetAllLimitsUseCase(limitRepository);
  final getLimitsByUserUseCase = GetLimitsByUserIdUseCase(limitRepository);
  final addLimitUseCase = CreateLimitUseCase(limitRepository);
  final updateLimitUseCase = UpdateLimitUseCase(limitRepository);
  final deleteLimitUseCase = DeleteLimitUseCase(limitRepository);

  final limitController = LimitController(
    getAllLimitsUseCase: getLimitsUseCase,
    createLimitUseCase: addLimitUseCase,
    updateLimitUseCase: updateLimitUseCase,
    deleteLimitUseCase: deleteLimitUseCase,
  );
  Get.put(limitController);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Birren App',
      home: authController.loginType.value.isEmpty
          ? LoginPage()
          : HomePage(),
    );
  }
}
