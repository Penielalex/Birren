import 'dart:io';

import 'package:birren/data/service/bank_sms_log_service.dart';
import 'package:birren/data/service/sms_platform_service.dart';

import 'package:birren/data/service/sms_service.dart';

import 'package:birren/presentation/controllers/auth_controller.dart';

import 'package:birren/presentation/theme/colors.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

import 'data/db/app_database.dart';

import 'data/db/user_dao.dart';

import 'data/db/bank_dao.dart';

import 'data/db/transaction_dao.dart';

import 'data/db/budget_dao.dart';
import 'data/db/limit_dao.dart';
import 'data/db/loan_dao.dart';

import 'data/repository_impl/user_repository_impl.dart';

import 'data/repository_impl/bank_repository_impl.dart';

import 'data/repository_impl/transaction_repository_impl.dart';

import 'data/repository_impl/budget_repository_impl.dart';
import 'data/repository_impl/limit_repository_impl.dart';
import 'data/repository_impl/loan_repository_impl.dart';

import 'app/user_usecases.dart';

import 'app/bank_usecases.dart';

import 'app/transaction_usecases.dart';

import 'app/budget_usecases.dart';
import 'app/limit_usecases.dart';
import 'app/loan_usecases.dart';

import 'presentation/controllers/user_controller.dart';

import 'presentation/controllers/bank_controller.dart';

import 'presentation/controllers/transaction_controller.dart';

import 'presentation/controllers/budget_controller.dart';
import 'presentation/controllers/app_navigation_controller.dart';
import 'presentation/controllers/limit_controller.dart';
import 'presentation/controllers/loan_controller.dart';

import 'data/service/shared_prefs_service.dart';

import 'data/service/backup_service.dart';

import 'presentation/pages/app_root.dart';

import 'data/api/user_api.dart';



void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await HomeWidget.setAppGroupId('com.example.birren');
  }



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

  final smsPlatform = SmsPlatformService();

  final smsServices = SmsService(smsPlatform: smsPlatform);
  final bankSmsLogService = BankSmsLogService(smsPlatform: smsPlatform);

  final authController = AuthController(

    prefs: prefs,

    getUsers: getUsersUseCase,

    addUser: addUserUseCase,

    updateUser: updateUserUseCase,

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

    bankSmsLogService: bankSmsLogService,

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

  final linkInternalTransferUseCase =
      LinkInternalTransferUseCase(transactionRepository);

  final linkInternalTransferToCashUseCase =
      LinkInternalTransferToCashUseCase(transactionRepository);

  final deleteTransactionUseCase = DeleteTransactionUseCase(transactionRepository);



  final transactionController = TransactionController(

    prefs: prefs,

    getAllTransactionsUseCase: getTransactionsUseCase,

    getTransactionsByBankIdUseCase: getTransactionsByBankUseCase,

    createTransactionUseCase: addTransactionUseCase,

    updateTransactionUseCase: updateTransactionUseCase,

    linkInternalTransferUseCase: linkInternalTransferUseCase,

    linkInternalTransferToCashUseCase: linkInternalTransferToCashUseCase,

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

  final getLimitByUserUseCase = GetLimitByUserIdUseCase(limitRepository);

  final addLimitUseCase = CreateLimitUseCase(limitRepository);

  final updateLimitUseCase = UpdateLimitUseCase(limitRepository);

  final deleteLimitUseCase = DeleteLimitUseCase(limitRepository);



  final limitController = LimitController(

    prefs: prefs,

    getLimitByUserIdUseCase: getLimitByUserUseCase,

    getAllLimitsUseCase: getLimitsUseCase,

    createLimitUseCase: addLimitUseCase,

    updateLimitUseCase: updateLimitUseCase,

    deleteLimitUseCase: deleteLimitUseCase,

  );

  Get.put(limitController);

  final budgetDao = BudgetDao(db);
  final budgetRepository = BudgetRepositoryImpl(
    budgetDao: budgetDao,
    transactionDao: transactionDao,
  );
  final getActiveBudgetUseCase = GetActiveBudgetUseCase(budgetRepository);
  final getBudgetHistoryUseCase = GetBudgetHistoryUseCase(budgetRepository);
  final createBudgetUseCase = CreateBudgetUseCase(budgetRepository);
  final updateBudgetUseCase = UpdateBudgetUseCase(budgetRepository);
  final deleteBudgetUseCase = DeleteBudgetUseCase(budgetRepository);

  final budgetController = BudgetController(
    prefs: prefs,
    getActiveBudgetUseCase: getActiveBudgetUseCase,
    getBudgetHistoryUseCase: getBudgetHistoryUseCase,
    createBudgetUseCase: createBudgetUseCase,
    updateBudgetUseCase: updateBudgetUseCase,
    deleteBudgetUseCase: deleteBudgetUseCase,
  );

  Get.put(budgetController);

  Get.put(AppNavigationController());

  final loanDao = LoanDao(db);
  final loanRepository = LoanRepositoryImpl(dao: loanDao);
  final getLoansByUserIdUseCase = GetLoansByUserIdUseCase(loanRepository);
  final getOpenLoansByUserIdUseCase =
      GetOpenLoansByUserIdUseCase(loanRepository);
  final createLoanFromDisbursementUseCase =
      CreateLoanFromDisbursementUseCase(loanRepository);
  final createLoanFromLendUseCase =
      CreateLoanFromLendUseCase(loanRepository);
  final linkRepaymentToLoanUseCase =
      LinkRepaymentToLoanUseCase(loanRepository);
  final linkReturnToLentLoanUseCase =
      LinkReturnToLentLoanUseCase(loanRepository);
  final closeLoanUseCase = CloseLoanUseCase(loanRepository);
  final getReturnTransactionsForLoanUseCase =
      GetReturnTransactionsForLoanUseCase(loanRepository);

  final loanController = LoanController(
    prefs: prefs,
    getLoansByUserIdUseCase: getLoansByUserIdUseCase,
    getOpenLoansByUserIdUseCase: getOpenLoansByUserIdUseCase,
    createLoanFromDisbursementUseCase: createLoanFromDisbursementUseCase,
    createLoanFromLendUseCase: createLoanFromLendUseCase,
    linkRepaymentToLoanUseCase: linkRepaymentToLoanUseCase,
    linkReturnToLentLoanUseCase: linkReturnToLentLoanUseCase,
    closeLoanUseCase: closeLoanUseCase,
    getReturnTransactionsForLoanUseCase: getReturnTransactionsForLoanUseCase,
  );

  Get.put(loanController);

  final backupService = BackupService(
    db: db,
    userDao: userDao,
    bankDao: bankDao,
    transactionDao: transactionDao,
    budgetDao: budgetDao,
    loanDao: loanDao,
    limitDao: limitDao,
    prefs: prefs,
  );
  Get.put(backupService);

  runApp(const MyApp());

}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Birren App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          surface: AppColors.background,
          onSurface: Colors.white,
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: Colors.white),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
        dialogTheme: const DialogThemeData(
          titleTextStyle: TextStyle(color: Colors.white),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const AppRoot(),
    );
  }
}


