import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/cash_bank.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/bank.dart';
import '../../domain/entities/transaction.dart';

void showInternalTransferPairDialog(
  BuildContext context,
  Transaction primary,
) {
  final transactionController = Get.find<TransactionController>();
  final bankController = Get.find<BankController>();
  final oppositeType = primary.type == 'Expense' ? 'Income' : 'Expense';
  final dateLabel = DateFormat.yMMMd().format(primary.dateOf);
  final formatter = NumberFormat('#,##0.00');

  Bank? cashBank;
  for (final bank in bankController.banks) {
    if (isCashBankName(bank.bankName)) {
      cashBank = bank;
      break;
    }
  }

  showAppDialog(
    context: context,
    builder: (dialogContext) {
      return AppDialog(
        title: 'Link internal transfer',
        subtitle:
            'Selected ${primary.type} of ${formatter.format(primary.amount)} '
            'on $dateLabel. Choose the matching $oppositeType, or move it to Cash.',
        expandBody: true,
        scrollable: false,
        maxHeight: 520,
        actions: [
          AppDialogActions.cancel(dialogContext),
        ],
        child: Obx(() {
          final candidates =
              transactionController.getSameDayPairCandidates(primary);

          if (candidates.isEmpty && cashBank == null) {
            return Center(
              child: Text(
                'No matching $oppositeType transactions found on this day.',
                style: AppTextStyles.body1.copyWith(color: AppColors.mutedText),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: candidates.length + (cashBank == null ? 0 : 1),
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              if (cashBank != null && index == 0) {
                final bank = cashBank;
                final cashLabel = bank.displayName ?? bank.bankName;
                final cashPrefix = primary.type == 'Expense' ? '+' : '-';
                final cashSubtitle = primary.type == 'Expense'
                    ? 'Record income in $cashLabel'
                    : 'Record expense from $cashLabel';

                return AppDialogOptionTile(
                  title:
                      '$cashPrefix${formatter.format(primary.amount)} → Cash',
                  subtitle: cashSubtitle,
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: Colors.greenAccent,
                  ),
                  trailing: const Icon(
                    Icons.link_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  onTap: () async {
                    try {
                      await transactionController.linkInternalTransferToCash(
                        primary,
                        bank,
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      AppSnackbar.showSuccess(
                        'Internal transfer linked to Cash',
                      );
                    } catch (e) {
                      AppSnackbar.showError(e.toString());
                    }
                  },
                );
              }

              final candidateIndex = cashBank == null ? index : index - 1;
              final candidate = candidates[candidateIndex];
              final bank = bankController.banks.firstWhere(
                (b) => b.id == candidate.bankId,
                orElse: () => throw Exception('Bank not found'),
              );
              final bankLabel = bank.displayName ?? bank.bankName;
              final prefix = candidate.type == 'Income' ? '+' : '-';

              return AppDialogOptionTile(
                title: '$prefix${formatter.format(candidate.amount)}',
                subtitle:
                    '$bankLabel • ${DateFormat.jm().format(candidate.dateOf)}',
                trailing: const Icon(
                  Icons.link_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                onTap: () async {
                  try {
                    await transactionController.linkInternalTransfer(
                      primary,
                      candidate,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  } catch (e) {
                    AppSnackbar.showError(e.toString());
                  }
                },
              );
            },
          );
        }),
      );
    },
  );
}
