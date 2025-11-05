import 'package:logger/logger.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;
  final logger =Logger();

  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<Map<String, dynamic>?>  fetchLastAmount({
    required String sender,
  }) async {

   try{
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.ADDRESS).equals(sender),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    // Iterate over messages to find the first one with a valid transaction
    for (var msg in messages) {
      final transaction = parseBankSmsByBank(msg.address, msg.body);

      if (transaction != null) {
        logger.i(transaction);
        return transaction; // or return transaction if you prefer
      }
    } }catch(e, stack){
     logger.e("Error fetching messages for $sender: $e");
     logger.e(stack);
     return null;
   }

    return null;
  }

  Map<String, dynamic>? parseBankSmsByBank(String? bank, String? body) {
    String? transactionType;
    double? firstAmount;
    double? balanceAmount;

    switch (bank?.toLowerCase()) {
      case 'boa': // Bank of Abyssinia
        final typesBOA = ['credited', 'debited'];
        for (var type in typesBOA) {
          if (body!.toLowerCase().contains(type)) {
            transactionType = type;
            break;
          }
        }
        final firstAmountRegExpBOA = RegExp(r'ETB\s*([\d,]+\.?\d*)', caseSensitive: false);
        final firstMatchBOA = firstAmountRegExpBOA.firstMatch(body!);
        if (firstMatchBOA != null) {
          firstAmount = double.tryParse(firstMatchBOA.group(1)!.replaceAll(',', ''));
        }
        final balanceRegExpBOA = RegExp(r'Available Balance\s*:?\s*ETB\s*([\d,]+\.?\d*)', caseSensitive: false);
        final balanceMatchBOA = balanceRegExpBOA.firstMatch(body);
        if (balanceMatchBOA != null) {
          balanceAmount = double.tryParse(balanceMatchBOA.group(1)!.replaceAll(',', ''));
        }
        break;

      case 'cbe': // Commercial Bank of Ethiopia
        final typesCBE = ['credited', 'debited'];
        for (var type in typesCBE) {
          if (body!.toLowerCase().contains(type)) {
            transactionType = type;
            break;
          }
        }
        final firstAmountRegExpCBE = RegExp(r'ETB\s*([\d,]+\.?\d*)', caseSensitive: false);
        final firstMatchCBE = firstAmountRegExpCBE.firstMatch(body!);
        if (firstMatchCBE != null) {
          firstAmount = double.tryParse(firstMatchCBE.group(1)!.replaceAll(',', ''));
        }
        final balanceRegExpCBE = RegExp(r'Current Balance is\s*:?\s*ETB\s*([\d,]+\.?\d*)', caseSensitive: false);
        final balanceMatchCBE = balanceRegExpCBE.firstMatch(body);
        if (balanceMatchCBE != null) {
          balanceAmount = double.tryParse(balanceMatchCBE.group(1)!.replaceAll(',', ''));
        }
        break;

      case '127': // Bank 127
        final types127 = ['transferred', 'recharged', 'paid', 'received'];
        for (var type in types127) {
          if (body!.toLowerCase().contains(type)) {
            transactionType = type;
            break;
          }
        }
        final firstAmountRegExp127 = RegExp(r'ETB\s*([\d,]+\.?\d*)', caseSensitive: false);
        final firstMatch127 = firstAmountRegExp127.firstMatch(body!);
        if (firstMatch127 != null) {
          firstAmount = double.tryParse(firstMatch127.group(1)!.replaceAll(',', ''));
        }
        final balanceRegExp127 = RegExp(r'balance is\s*:?\s*ETB\s*([\d,]+\.?\d*)', caseSensitive: false);
        final balanceMatch127 = balanceRegExp127.firstMatch(body);
        if (balanceMatch127 != null) {
          balanceAmount = double.tryParse(balanceMatch127.group(1)!.replaceAll(',', ''));
        }
        break;

      case 'mpesa': // M-PESA
        final typesMpesa = ['received', 'sent', 'bought', 'paid'];
        for (var type in typesMpesa) {
          if (body!.toLowerCase().contains(type)) {
            transactionType = type;
            break;
          }
        }

        // First amount: number before "birr"
        final firstAmountRegExpMpesa = RegExp(r'([\d,]+\.?\d*)\s*birr', caseSensitive: false);
        final firstMatchMpesa = firstAmountRegExpMpesa.firstMatch(body!);
        if (firstMatchMpesa != null) {
          firstAmount = double.tryParse(firstMatchMpesa.group(1)!.replaceAll(',', ''));
        }

        // Balance amount: after "balance is" and before "Birr"
        final balanceRegExpMpesa = RegExp(r'balance is\s*:?\s*([\d,]+\.?\d*)\s*birr', caseSensitive: false);
        final balanceMatchMpesa = balanceRegExpMpesa.firstMatch(body);
        if (balanceMatchMpesa != null) {
          balanceAmount = double.tryParse(balanceMatchMpesa.group(1)!.replaceAll(',', ''));
        }
        break;

      default:
        print("Bank parser not implemented for $bank");
    }

    if (transactionType != null && firstAmount != null && balanceAmount != null) {
      return {
        'transactionType': transactionType,
        'firstAmount': firstAmount,
        'balanceAmount': balanceAmount,
      };
    }

    // Return null if any of the three is null
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchTransactionsForBank({
    required String address,
    required DateTime fromDate,
  }) async {
    List<Map<String, dynamic>> allTransactions = [];

    try {
      // Fetch SMS messages from the given address
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(address),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      for (var msg in messages) {
        final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0);

        // Skip messages older than fromDate
        if (msgDate.isBefore(fromDate)) continue;

        final transaction = parseBankSmsByBank(msg.address, msg.body);

        // Only include if all required fields are non-null
        if (transaction != null &&
            transaction['transactionType'] != null &&
            transaction['firstAmount'] != null &&
            transaction['balanceAmount'] != null) {
          allTransactions.add({
            'transactionType': transaction['transactionType'],
            'firstAmount': transaction['firstAmount'],
            'balanceAmount': transaction['balanceAmount'],
            'date': msgDate,
            'address': msg.address,

          });
        }
      }

      // Sort transactions by date descending
      allTransactions.sort(
              (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Debug log
      for (var tr in allTransactions) {
        logger.i(tr);
      }
    } catch (e, stack) {
      logger.e("Error fetching transactions for address $address: $e");
      logger.e(stack);
    }

    return allTransactions;
  }


}
