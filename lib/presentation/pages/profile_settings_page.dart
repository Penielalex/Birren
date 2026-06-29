import 'package:birren/presentation/controllers/auth_controller.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/pages/app_root.dart';
import 'package:birren/presentation/pages/budget_history_page.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:birren/data/service/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final AuthController authController = Get.find<AuthController>();
  final BackupService backupService = Get.find<BackupService>();
  bool _isBusy = false;

  Future<void> _setPin() async {
    final pin = await _promptPinDialog(
      title: 'Set PIN',
      confirm: true,
    );
    if (pin == null) return;

    try {
      await authController.setPin(pin);
      AppSnackbar.showSuccess('PIN enabled');
    } catch (e) {
      AppSnackbar.showError(e.toString());
    }
  }

  Future<void> _changePin() async {
    final current = await _promptPinDialog(title: 'Current PIN');
    if (current == null) return;
    final newPin = await _promptPinDialog(
      title: 'New PIN',
      confirm: true,
    );
    if (newPin == null) return;

    try {
      await authController.changePin(current, newPin);
      AppSnackbar.showSuccess('PIN updated');
    } catch (e) {
      AppSnackbar.showError(e.toString());
    }
  }

  Future<void> _removePin() async {
    final current = await _promptPinDialog(title: 'Enter PIN to remove');
    if (current == null) return;

    try {
      await authController.removePin(current);
      AppSnackbar.showSuccess('PIN removed');
      setState(() {});
    } catch (e) {
      AppSnackbar.showError(e.toString());
    }
  }

  Future<String?> _promptPinDialog({
    required String title,
    bool confirm = false,
  }) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(title, style: AppTextStyles.headline1),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: pinController,
              hintText: 'PIN (4+ digits)',
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            if (confirm) ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: confirmController,
                hintText: 'Confirm PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.smallButton2),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length < 4) {
                AppSnackbar.showError('PIN must be at least 4 digits');
                return;
              }
              if (confirm && pin != confirmController.text.trim()) {
                AppSnackbar.showError('PINs do not match');
                return;
              }
              Navigator.pop(context, pin);
            },
            child: Text('Save', style: AppTextStyles.smallButton1),
          ),
        ],
      ),
    );

    pinController.dispose();
    confirmController.dispose();
    return result;
  }

  Future<void> _exportData() async {
    setState(() => _isBusy = true);
    try {
      await backupService.shareBackup();
      AppSnackbar.showSuccess('Backup ready to share');
    } catch (e) {
      AppSnackbar.showError('Export failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Import data?', style: AppTextStyles.headline1),
        content: Text(
          'This replaces all current data with the backup file.',
          style: AppTextStyles.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.smallButton2),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Import', style: AppTextStyles.smallButton1),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await backupService.importFromFile(result.files.single.path!);
      await _refreshAllData();
      AppSnackbar.showSuccess('Data imported');
    } catch (e) {
      AppSnackbar.showError('Import failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _refreshAllData() async {
    final authController = Get.find<AuthController>();
    final bankController = Get.find<BankController>();
    final transactionController = Get.find<TransactionController>();
    final budgetController = Get.find<BudgetController>();

    await authController.refreshUsers();
    await bankController.fetchBanks();
    await transactionController.fetchSavedTransactions();
    await budgetController.refreshBudgets();
    await Get.find<LoanController>().refreshLoans();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Log out and erase data?', style: AppTextStyles.headline1),
        content: Text(
          'Logging out will permanently delete all data on this device, '
          'including banks, transactions, budgets, and your PIN. '
          'This cannot be undone. Export a backup first if you want to keep your data.',
          style: AppTextStyles.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.smallButton2),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete all & log out',
              style: AppTextStyles.smallButton1.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await authController.logout();
      Get.offAll(() => const AppRoot());
    } catch (e) {
      AppSnackbar.showError('Logout failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.headline1),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Obx(() {
                  final name = authController.users.isNotEmpty
                      ? authController.users.first.name
                      : 'User';
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(name, style: AppTextStyles.headline1),
                    subtitle: Text('Local account', style: AppTextStyles.body1),
                  );
                }),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.white),
                  title: Text('Budget history', style: AppTextStyles.body1),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BudgetHistoryPage(),
                        ),
                      ),
                ),
                Obx(() {
                  final enabled = authController.pinEnabled.value;
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.pin, color: Colors.white),
                        title: Text(
                          enabled ? 'Change PIN' : 'Set app PIN',
                          style: AppTextStyles.body1,
                        ),
                        subtitle: Text(
                          enabled
                              ? 'Required when opening the app'
                              : 'Optional 4+ digit PIN',
                          style: AppTextStyles.lightBody1,
                        ),
                        onTap: enabled ? _changePin : _setPin,
                      ),
                      if (enabled)
                        ListTile(
                          leading: const Icon(Icons.no_encryption,
                              color: Colors.red),
                          title: Text(
                            'Remove PIN',
                            style: AppTextStyles.body1.copyWith(
                              color: Colors.red,
                            ),
                          ),
                          onTap: _removePin,
                        ),
                    ],
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.upload, color: Colors.white),
                  title: Text('Export data', style: AppTextStyles.body1),
                  subtitle: Text(
                    'Save a JSON backup to share or store',
                    style: AppTextStyles.lightBody1,
                  ),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.white),
                  title: Text('Import data', style: AppTextStyles.body1),
                  subtitle: Text(
                    'Restore from a Birren backup file',
                    style: AppTextStyles.lightBody1,
                  ),
                  onTap: _importData,
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Log out & erase data',
                    style: AppTextStyles.body1.copyWith(color: Colors.red),
                  ),
                  subtitle: Text(
                    'Deletes everything on this device',
                    style: AppTextStyles.lightBody1,
                  ),
                  onTap: _logout,
                ),
              ],
            ),
    );
  }
}
