import 'package:birren/core/app_logger.dart';

import 'package:birren/data/models/sms_message_model.dart';

import 'package:birren/data/service/sms_platform_service.dart';

import 'package:birren/data/service/sms_regex_parser.dart';

import 'package:birren/domain/entities/parsed_sms_transaction.dart';

import 'package:permission_handler/permission_handler.dart';



class SmsService {

  final SmsPlatformService smsPlatform;

  final logger = appLogger;



  static const _pageSize = 50;

  static const initialTransactionCount = 5;



  SmsService({

    required this.smsPlatform,

  });



  Future<bool> requestPermission() async {

    final status = await Permission.sms.request();

    return status.isGranted;

  }



  /// Logs raw SMS bodies for a bank — useful for building new regex patterns.

  Future<void> logAllSmsForBank({

    required String address,

    int limit = 50,

  }) async {

    try {

      final messages = await smsPlatform.getSmsByDateRange(

        startDate: DateTime(2000),

        endDate: DateTime.now(),

        sender: address,

        limit: limit,

        offset: 0,

      );



      logger.i('[SMS_DUMP] $address: ${messages.length} message(s)');

      for (final msg in messages) {

        logger.i('[SMS_DUMP][$address] ${msg.body}');

      }

    } catch (e, stack) {

      logger.e('Failed to dump SMS for $address: $e');

      logger.e(stack);

    }

  }



  Future<Map<String, dynamic>?> fetchLastAmount({

    required String sender,

  }) async {

    logger.i("fetching last amount for $sender");

    try {

      final msg = await smsPlatform.getLatestSms(sender: sender);

      if (msg == null) {

        logger.i("no messages found for $sender");

        return null;

      }



      logger.i(msg.body);

      final transaction = _parseSmsBody(msg.body, bank: sender);

      if (transaction == null) {

        logger.i("no transaction found in latest message for $sender");

        return null;

      }



      return transaction.toSmsMap(

        date: msg.date ?? DateTime.fromMillisecondsSinceEpoch(0),

        address: msg.address,

      );

    } catch (e, stack) {

      logger.e("Error fetching messages for $sender: $e");

      logger.e(stack);

      return null;

    }

  }



  ParsedSmsTransaction? _parseSmsBody(

    String? body, {

    String? bank,

  }) {

    if (body == null || body.trim().isEmpty) {

      logger.i("Parsing sms body is null or empty");

      return null;

    }



    if (bank == null) {

      logger.w('Cannot parse SMS without bank sender');

      return null;

    }



    final parsed = SmsRegexParser.parse(bank: bank, body: body);

    if (parsed != null && parsed.isActionable) {

      logger.i(

        'Parsed via regex: type=${parsed.transactionType} '

        'amount=${parsed.amount} balance=${parsed.balance}',

      );

      return parsed;

    }



    logger.w('Regex parse failed for $bank: ${body.substring(0, body.length.clamp(0, 120))}...');

    return null;

  }



  Future<List<Map<String, dynamic>>> fetchInitialTransactionsForBank({

    required String address,

    int count = initialTransactionCount,

  }) async {

    final results = <Map<String, dynamic>>[];

    var offset = 0;



    try {

      while (results.length < count) {

        final messages = await smsPlatform.getSmsByDateRange(

          startDate: DateTime(2000),

          endDate: DateTime.now(),

          sender: address,

          limit: _pageSize,

          offset: offset,

        );



        if (messages.isEmpty) {

          break;

        }



        for (final msg in messages) {

          final transaction = _parseSmsBody(msg.body, bank: address);

          if (transaction == null || !transaction.isActionable) {

            continue;

          }



          results.add(transaction.toSmsMap(

            date: msg.date ?? DateTime.fromMillisecondsSinceEpoch(0),

            address: msg.address,

          ));



          if (results.length >= count) {

            break;

          }

        }



        if (messages.length < _pageSize) {

          break;

        }

        offset += _pageSize;

      }



      results.sort(

        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),

      );



      logger.i(

        'Initial fetch for $address: ${results.length} actionable message(s)',

      );

    } catch (e, stack) {

      logger.e('Error fetching initial transactions for $address: $e');

      logger.e(stack);

    }



    return results;

  }



  Future<List<Map<String, dynamic>>> fetchTransactionsForBank({

    required String address,

    required DateTime fromDate,

    bool exclusiveStart = false,

  }) async {

    final allTransactions = <Map<String, dynamic>>[];



    try {

      var offset = 0;

      while (true) {

        final messages = await smsPlatform.getSmsByDateRange(

          startDate: fromDate,

          endDate: DateTime.now(),

          sender: address,

          limit: _pageSize,

          offset: offset,

        );



        if (messages.isEmpty) {

          break;

        }



        for (final msg in messages) {

          final msgDate = msg.date ?? DateTime.fromMillisecondsSinceEpoch(0);

          if (exclusiveStart && !msgDate.isAfter(fromDate)) {

            continue;

          }



          final transaction = _parseSmsBody(msg.body, bank: address);

          if (transaction != null && transaction.isActionable) {

            allTransactions.add(transaction.toSmsMap(

              date: msgDate,

              address: msg.address,

            ));

          }

        }



        if (messages.length < _pageSize) {

          break;

        }

        offset += _pageSize;

      }



      allTransactions.sort(

        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),

      );



      for (final tr in allTransactions) {

        logger.i(

          'SMS transaction: type=${tr['transactionType']} '

          'amount=${tr['firstAmount']} balance=${tr['balanceAmount']} '

          'date=${tr['date']}',

        );

      }

    } catch (e, stack) {

      logger.e("Error fetching transactions for address $address: $e");

      logger.e(stack);

    }



    return allTransactions;

  }

  /// Finds the inbox SMS that best matches a saved transaction.
  Future<SmsMessageModel?> findSmsForTransaction({
    required String bankAddress,
    required DateTime dateOf,
    required double amount,
    required String type,
  }) async {
    final dayStart = DateTime(dateOf.year, dateOf.month, dateOf.day);
    final dayEnd = DateTime(dateOf.year, dateOf.month, dateOf.day, 23, 59, 59, 999);

    SmsMessageModel? bestMatch;
    var bestScore = -1;

    try {
      var offset = 0;
      while (true) {
        final messages = await smsPlatform.getSmsByDateRange(
          startDate: dayStart,
          endDate: dayEnd,
          sender: bankAddress,
          limit: _pageSize,
          offset: offset,
        );

        if (messages.isEmpty) break;

        for (final msg in messages) {
          final parsed = _parseSmsBody(msg.body, bank: bankAddress);
          if (parsed == null || !parsed.isActionable) continue;

          final msgType = parsed.transactionType == 'income'
              ? 'Income'
              : parsed.transactionType == 'withdrawal'
                  ? 'Expense'
                  : null;
          if (msgType != type) continue;

          final parsedAmount = parsed.amount ?? 0;
          final amountDiff = (parsedAmount - amount).abs();
          final msgDate = msg.date ?? dateOf;
          final timeDiffSeconds = msgDate.difference(dateOf).inSeconds.abs();

          final exactAmount = amountDiff < 0.01;
          final score = (exactAmount ? 1000000 : 0) -
              timeDiffSeconds -
              (amountDiff * 100).round();

          if (score > bestScore) {
            bestScore = score;
            bestMatch = msg;
          }
        }

        if (messages.length < _pageSize) break;
        offset += _pageSize;
      }
    } catch (e, stack) {
      logger.e('Error finding SMS for $bankAddress transaction: $e');
      logger.e(stack);
    }

    return bestMatch;
  }

}
