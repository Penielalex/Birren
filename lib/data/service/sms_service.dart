// import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class SmsService {
//   final SmsQuery _query = SmsQuery();
//
//   /// Request SMS permission
//   Future<bool> requestPermission() async {
//     final status = await Permission.sms.status;
//     if (status.isGranted) return true;
//
//     final result = await Permission.sms.request();
//     return result.isGranted;
//   }
//
//   Future<SmsMessage?> fetchLatestMessageForBank(String bankName) async {
//     final messages = await _query.querySms(
//       kinds: [SmsQueryKind.inbox],
//       sort: true,
//       count: 200,
//     );
//
//     for (final msg in messages) {
//       final body = msg.body?.toLowerCase() ?? '';
//       final sender = msg.address?.toLowerCase() ?? '';
//
//       if (body.contains(bankName.toLowerCase()) ||
//           sender.contains(bankName.toLowerCase())) {
//         return msg;
//       }
//     }
//
//     return null;
//   }
//
//   double extractAmount(String messageBody) {
//     final regex = RegExp(r'(\d{1,3}(,\d{3})*(\.\d{1,2})?)');
//     final match = regex.firstMatch(messageBody);
//     if (match != null) {
//       return double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0.0;
//     }
//     return 0.0;
//   }
// }
