import 'package:birren/data/service/sms_regex_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests built from live SMS logs in sms_logs/*.md
void main() {
  group('CBE', () {
    test('transfer uses total including fees', () {
      const sms =
          'Dear Peniel You have successfully transferred ETB500.00 from account '
          '1********0152. Service charge of ETB 0.50 and VAT(15%) of ETB0.08 and '
          'Disaster Recovery(5%) of 0.03 with total of ETB500.61 .'
          'Your current balance is ETB486.74. Thanks for Banking with CBE.';

      final r = SmsRegexParser.parse(bank: 'CBE', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 500.61);
      expect(r.balance, 486.74);
    });

    test('debit transaction uses total including fees', () {
      const sms =
          'Dear Peniel A debit transaction of ETB 3300.0. has occurred on your account '
          '1********0152. Service charge of ETB 10.00 and VAT(15%) of ETB1.50 and '
          'Disaster Recovery(5%) of 0.50 with total of ETB3312.00 .'
          'Your current balance is ETB2,285.16. Thanks for Banking with CBE.';

      final r = SmsRegexParser.parse(bank: 'CBE', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 3312.0);
      expect(r.balance, 2285.16);
    });

    test('simple credit', () {
      const sms =
          'Dear Miss Peniel your Account 1********0152 has been credited with ETB 10. '
          'Your Current Balance is ETB 2295.16. Thank you for Banking with CBE!';

      final r = SmsRegexParser.parse(bank: 'CBE', body: sms)!;
      expect(r.transactionType, 'income');
      expect(r.amount, 10.0);
      expect(r.balance, 2295.16);
    });

    test('credit by person', () {
      const sms =
          'Dear Miss your Account 1********0152 has been credited by BETSELOT BERHANU ADANE '
          'with ETB 10. Your Current Balance is ETB 554.45. Thank you for Banking with CBE!';

      final r = SmsRegexParser.parse(bank: 'CBE', body: sms)!;
      expect(r.transactionType, 'income');
      expect(r.amount, 10.0);
      expect(r.balance, 554.45);
    });
  });

  group('BOA', () {
    test('debit', () {
      const sms =
          'Dear Peniel, your account 8*****97 was debited with ETB 130.94. '
          'Available Balance: ETB 3,306.29.';

      final r = SmsRegexParser.parse(bank: 'BOA', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 130.94);
      expect(r.balance, 3306.29);
    });

    test('credit', () {
      const sms =
          'Dear Peniel, your account 8*****97 was credited with ETB 200.00 by Peniel. '
          'Available Balance: ETB 4,449.23.';

      final r = SmsRegexParser.parse(bank: 'BOA', body: sms)!;
      expect(r.transactionType, 'income');
      expect(r.amount, 200.0);
      expect(r.balance, 4449.23);
    });

    test('POS lock is ignored (debit SMS is the real transaction)', () {
      const lockSms =
          'Dear PINIEL, ETB 2440.00 is Locked From Your Account Number '
          '8****97 Due to POS TRANSACTION at IDDO CAFE. '
          'Your Available Balance is ETB 67721.22';

      expect(SmsRegexParser.parse(bank: 'BOA', body: lockSms), isNull);

      const debitSms =
          'Dear PINIEL, your account 8*****97 was debited with ETB 2,440.00. '
          'Available Balance: ETB 67,721.22.';

      final r = SmsRegexParser.parse(bank: 'BOA', body: debitSms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 2440.0);
      expect(r.balance, 67721.22);
    });
  });

  group('127 telebirr', () {
    test('transfer includes service fee and VAT', () {
      const sms =
          'Dear Peniel You have transferred ETB 2,500.00 to NITSHUFIKER GIRMA '
          'on 29/06/2026. The service fee is ETB 5.22 and 15% VAT on the service fee '
          'is ETB 0.78. Your current E-Money Account balance is ETB 103.60.';

      final r = SmsRegexParser.parse(bank: '127', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 2506.0);
      expect(r.balance, 103.6);
    });

    test('small transfer fees', () {
      const sms =
          'You have transferred ETB 20.00 to Muluken on 25/06/2026. '
          'The service fee is ETB 0.87 and 15% VAT on the service fee is ETB 0.13. '
          'Your current E-Money Account balance is ETB 109.60.';

      final r = SmsRegexParser.parse(bank: '127', body: sms)!;
      expect(r.amount, 21.0);
    });

    test('paid for goods', () {
      const sms =
          'You have paid ETB 300.00 for goods purchased from 867087 - YEBAZ PLC. '
          'Your current balance is ETB 775.60.';

      final r = SmsRegexParser.parse(bank: '127', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 300.0);
      expect(r.balance, 775.6);
    });

    test('received from bank', () {
      const sms =
          'You have received ETB 2,500.00 by transaction number DFT8D94VMO '
          'from Bank of Abyssinia to your telebirr Account. Your current balance is ETB 2,609.60.';

      final r = SmsRegexParser.parse(bank: '127', body: sms)!;
      expect(r.transactionType, 'income');
      expect(r.amount, 2500.0);
      expect(r.balance, 2609.6);
    });

    test('recharged airtime', () {
      const sms =
          'You have recharged ETB 50.00 airtime for 942538916. '
          'Your current balance is ETB 457.60.';

      final r = SmsRegexParser.parse(bank: '127', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 50.0);
      expect(r.balance, 457.6);
    });
  });

  group('MPESA', () {
    test('sent includes transaction fee', () {
      const sms =
          'Dear Peniel, you have sent 2,353.00 Birr to Commercial Bank of Ethiopia '
          'on 28/6/26. Transaction number UFS08HMUXK. Transaction Fee 2.35 Birr. '
          'Your new M-PESA balance is 177,728.39 Birr.';

      final r = SmsRegexParser.parse(bank: 'MPESA', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 2355.35);
      expect(r.balance, 177728.39);
    });

    test('paid merchant', () {
      const sms =
          'Dear Peniel, you have paid 490.00 Birr to 50045 - London Cafe. '
          'Transaction Fee 0.00 Birr. Your M-PESA balance is 1,143.53 Birr.';

      final r = SmsRegexParser.parse(bank: 'MPESA', body: sms)!;
      expect(r.transactionType, 'withdrawal');
      expect(r.amount, 490.0);
      expect(r.balance, 1143.53);
    });

    test('received salary', () {
      const sms =
          'Dear Peniel, you have received salary of 180,926.81 Birr from SAFARICOM '
          'on 24/6/26. Your new M-PESA balance is 181,990.34 Birr.';

      final r = SmsRegexParser.parse(bank: 'MPESA', body: sms)!;
      expect(r.transactionType, 'income');
      expect(r.amount, 180926.81);
      expect(r.balance, 181990.34);
    });

    test('received from person', () {
      const sms =
          'Dear Peniel, you have received 100.00 Birr from Abel on 16/6/26. '
          'Your current M-PESA balance is 1,633.53 Birr.';

      final r = SmsRegexParser.parse(bank: 'MPESA', body: sms)!;
      expect(r.transactionType, 'income');
      expect(r.amount, 100.0);
      expect(r.balance, 1633.53);
    });

    test('cashback is income', () {
      const sms =
          'Congratulations, you have received a cashback of 0.50 Birr for Paying via M-PESA';

      expect(SmsRegexParser.parse(bank: 'MPESA', body: sms), isNull);
    });
  });
}
