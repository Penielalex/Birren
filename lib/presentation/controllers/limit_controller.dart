import 'package:get/get.dart';
import '../../app/limit_usecases.dart';
import '../../domain/entities/limit.dart';


class LimitController extends GetxController {
  final GetAllLimitsUseCase getAllLimitsUseCase;
  final CreateLimitUseCase createLimitUseCase;
  final UpdateLimitUseCase updateLimitUseCase;
  final DeleteLimitUseCase deleteLimitUseCase;

  LimitController({
    required this.getAllLimitsUseCase,
    required this.createLimitUseCase,
    required this.updateLimitUseCase,
    required this.deleteLimitUseCase,
  });

  var limits = <Limit>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLimits();
  }

  Future<void> fetchLimits() async {
    try {
      isLoading.value = true;
      final result = await getAllLimitsUseCase.execute();
      limits.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLimit(Limit limit) async {
    await createLimitUseCase.execute(limit);
    await fetchLimits();
  }

  Future<void> editLimit(Limit limit) async {
    await updateLimitUseCase.execute(limit);
    await fetchLimits();
  }

  Future<void> removeLimit(int id) async {
    await deleteLimitUseCase.execute(id);
    await fetchLimits();
  }
}
