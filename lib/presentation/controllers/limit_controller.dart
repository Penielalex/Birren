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

  Future<void> addLimit(Limit limit) async {
    final userId = await prefs.getId();
    var limits = Limit(userId: int.parse(userId!), type: limit.type, amount: limit.amount, monthStartDay: limit.monthStartDay, monthStartType: limit.monthStartType, createdAt: limit.createdAt, updatedAt: limit.updatedAt);
    await createLimitUseCase.execute(limits);
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
