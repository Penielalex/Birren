import 'package:get/get.dart';
import '../../app/limit_usecases.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/limit.dart';


class LimitController extends GetxController {
  final SharedPrefsService prefs;
  final GetAllLimitsUseCase getAllLimitsUseCase;
  final CreateLimitUseCase createLimitUseCase;
  final UpdateLimitUseCase updateLimitUseCase;
  final DeleteLimitUseCase deleteLimitUseCase;
  final GetLimitByUserIdUseCase getLimitByUserIdUseCase;

  LimitController({
    required this.prefs,
    required this.getAllLimitsUseCase,
    required this.createLimitUseCase,
    required this.updateLimitUseCase,
    required this.deleteLimitUseCase,
    required this.getLimitByUserIdUseCase,
  });

  Rx<Limit?> limit = Rx<Limit?>(null);

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLimits();
  }

  Future<void> fetchLimits() async {
    try {
      final userId = await prefs.getId();
      isLoading.value = true;
      final result = await getLimitByUserIdUseCase.execute(int.parse(userId!));
      limit.value = result;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLimit(Limit newLimit) async {
    final userId = await prefs.getId();
    
    // Check if the user already has a limit
    if (limit.value != null) {
      // User has a limit already, update it instead of creating a new one
      final existingLimit = limit.value!;
      var updatedLimit = Limit(
        id: existingLimit.id,
        userId: int.parse(userId!), 
        type: newLimit.type, 
        amount: newLimit.amount, 
        monthStartDay: newLimit.monthStartDay, 
        monthStartType: newLimit.monthStartType, 
        createdAt: existingLimit.createdAt, 
        updatedAt: DateTime.now()
      );
      await updateLimitUseCase.execute(updatedLimit);
    } else {
      // No existing limit, create one
      var limitToCreate = Limit(
        userId: int.parse(userId!), 
        type: newLimit.type, 
        amount: newLimit.amount, 
        monthStartDay: newLimit.monthStartDay, 
        monthStartType: newLimit.monthStartType, 
        createdAt: newLimit.createdAt, 
        updatedAt: newLimit.updatedAt
      );
      await createLimitUseCase.execute(limitToCreate);
    }
    
    await fetchLimits();
  }

  Future<void> editLimit(Limit limit, int? id) async {
    final userId = await prefs.getId();
    var limits = Limit(id:id,userId: int.parse(userId!), type: limit.type, amount: limit.amount, monthStartDay: limit.monthStartDay, monthStartType: limit.monthStartType, createdAt: limit.createdAt, updatedAt: limit.updatedAt);
    await updateLimitUseCase.execute(limits);
    await fetchLimits();
  }

  Future<void> removeLimit(int id) async {
    await deleteLimitUseCase.execute(id);
    await fetchLimits();
  }
}
