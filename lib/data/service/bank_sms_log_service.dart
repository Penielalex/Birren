import 'dart:io';

import 'package:birren/core/app_logger.dart';
import 'package:birren/data/models/sms_message_model.dart';
import 'package:birren/data/service/sms_platform_service.dart';
import 'package:birren/data/service/sms_regex_parser.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Exports all inbox SMS for a bank sender to a per-bank markdown log file.
class BankSmsLogService {
  BankSmsLogService({required this.smsPlatform});

  final SmsPlatformService smsPlatform;
  final logger = appLogger;
  static const _pageSize = 50;
  static const _logDirName = 'sms_logs';
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Fetches every SMS from [bankName] and writes `{bankName}_sms_log.md`.
  /// Returns the saved file path, or null on failure.
  Future<String?> exportBankSmsToMarkdown({required String bankName}) async {
    try {
      final messages = await _fetchAllSms(bankName);
      final dir = await _logDirectory();
      final fileName = '${_safeFileName(bankName)}_sms_log.md';
      final file = File(p.join(dir.path, fileName));

      final buffer = StringBuffer()
        ..writeln('# $bankName SMS Log')
        ..writeln()
        ..writeln('- **Exported:** ${_dateFormat.format(DateTime.now())}')
        ..writeln('- **Total messages:** ${messages.length}')
        ..writeln('- **Sender address:** $bankName')
        ..writeln()
        ..writeln('---')
        ..writeln();

      for (var i = 0; i < messages.length; i++) {
        buffer.writeln(_formatMessageEntry(
          index: i + 1,
          bankName: bankName,
          message: messages[i],
        ));
        if (i < messages.length - 1) {
          buffer.writeln('---');
          buffer.writeln();
        }
      }

      await file.writeAsString(buffer.toString());
      logger.i('[SMS_LOG] Saved ${messages.length} message(s) to ${file.path}');
      return file.path;
    } catch (e, stack) {
      logger.e('[SMS_LOG] Failed to export SMS for $bankName: $e');
      logger.e(stack);
      return null;
    }
  }

  Future<List<SmsMessageModel>> _fetchAllSms(String address) async {
    final all = <SmsMessageModel>[];
    var offset = 0;

    while (true) {
      final page = await smsPlatform.getSmsByDateRange(
        startDate: DateTime(2000),
        endDate: DateTime.now(),
        sender: address,
        limit: _pageSize,
        offset: offset,
      );

      if (page.isEmpty) {
        break;
      }

      all.addAll(page);

      if (page.length < _pageSize) {
        break;
      }
      offset += _pageSize;
    }

    all.sort((a, b) {
      final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return all;
  }

  Future<Directory> _logDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _logDirName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  String _formatMessageEntry({
    required int index,
    required String bankName,
    required SmsMessageModel message,
  }) {
    final body = message.body?.trim() ?? '';
    final date = message.date != null
        ? _dateFormat.format(message.date!)
        : 'Unknown date';
    final parsed = body.isEmpty
        ? null
        : SmsRegexParser.parse(bank: bankName, body: body);

    final buffer = StringBuffer()
      ..writeln('## Message $index')
      ..writeln()
      ..writeln('- **Date:** $date');

    if (parsed != null && parsed.isActionable) {
      buffer.writeln(
        '- **Parsed:** ${parsed.transactionType} | '
        'amount: ${parsed.amount} | balance: ${parsed.balance}',
      );
    } else if (body.toLowerCase().contains('is locked from your account') &&
        body.toLowerCase().contains('pos transaction')) {
      buffer.writeln(
        '- **Parsed:** POS lock skipped (debit SMS is the transaction)',
      );
    } else {
      buffer.writeln('- **Parsed:** not actionable');
    }

    buffer
      ..writeln()
      ..writeln('```text')
      ..writeln(body.isEmpty ? '(empty body)' : body)
      ..writeln('```');

    return buffer.toString();
  }

  String _safeFileName(String bankName) {
    return bankName.replaceAll(RegExp(r'[^\w\-]+'), '_');
  }
}
