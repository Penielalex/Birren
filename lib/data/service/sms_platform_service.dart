import 'package:birren/data/models/sms_message_model.dart';
import 'package:flutter/services.dart';

class SmsPlatformService {
  static const MethodChannel _channel = MethodChannel('com.myapp.sms');

  Future<SmsMessageModel?> getLatestSms({String? sender}) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'getLatestSms',
        <String, dynamic>{
          if (sender != null) 'sender': sender,
        },
      );

      if (result == null) {
        return null;
      }

      return SmsMessageModel.fromMap(Map<dynamic, dynamic>.from(result as Map));
    } on PlatformException catch (e) {
      throw SmsPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to get latest SMS',
        details: e.details,
      );
    }
  }

  Future<List<SmsMessageModel>> getSmsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? sender,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'getSmsByDateRange',
        <String, dynamic>{
          'startDate': startDate.millisecondsSinceEpoch,
          'endDate': endDate.millisecondsSinceEpoch,
          if (sender != null) 'sender': sender,
          'limit': limit,
          'offset': offset,
        },
      );

      if (result == null) {
        return const [];
      }

      final list = result as List<dynamic>;
      return list
          .map(
            (item) => SmsMessageModel.fromMap(
              Map<dynamic, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on PlatformException catch (e) {
      throw SmsPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to get SMS by date range',
        details: e.details,
      );
    }
  }
}

class SmsPlatformException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const SmsPlatformException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'SmsPlatformException($code): $message';
}
