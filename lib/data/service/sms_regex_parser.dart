import 'package:birren/domain/entities/parsed_sms_transaction.dart';

/// Deterministic parsers for CBE, BOA, telebirr (127), and M-PESA SMS formats.
class SmsRegexParser {
  SmsRegexParser._();

  static final _etbAmount = RegExp(r'ETB\s*([\d,]+\.?\d*)', caseSensitive: false);

  static ParsedSmsTransaction? parse({
    required String bank,
    required String body,
  }) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    switch (bank.trim().toLowerCase()) {
      case 'boa':
        return _parseBoa(normalized);
      case 'cbe':
        return _parseCbe(normalized);
      case '127':
        return _parse127(normalized);
      case 'mpesa':
        return _parseMpesa(normalized);
      default:
        return null;
    }
  }

  // --- CBE -------------------------------------------------------------------

  static ParsedSmsTransaction? _parseCbe(String body) {
    final lower = body.toLowerCase();
    final type = _detectType(lower, [
      _TypeRule(r'debit transaction of etb', 'withdrawal'),
      _TypeRule(r'has been debited', 'withdrawal'),
      _TypeRule(r'successfully transferred', 'withdrawal'),
      _TypeRule(r'has been credited', 'income'),
      _TypeRule(r'credited with etb', 'income'),
      _TypeRule(r'received', 'income'),
      _TypeRule(r'deposited', 'income'),
    ]);

    final amount = _parseCbeAmount(body, type);
    final balance = _firstMatch([
      RegExp(
        r'(?:your\s+)?current\s+balance\s+is\s*:?\s*ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'available\s+balance\s*:?\s*ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);

    return _build(type: type, amount: amount, balance: balance);
  }

  static double? _parseCbeAmount(String body, String type) {
    if (type == 'withdrawal') {
      final totalDebited = _firstMatch([
        RegExp(
          r'with\s+total\s+of\s+ETB\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
      ], body);
      if (totalDebited != null) return totalDebited;

      final principal = _firstMatch([
        RegExp(
          r'debit transaction of ETB\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
        RegExp(r'transferred\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(
          r'(?:has\s*been\s+)?debited\s+with\s+ETB\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
        RegExp(r'withdrawn\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'paid\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false),
      ], body);

      final fees = _sumCbeFees(body);
      if (principal != null && fees > 0) return principal + fees;
      if (principal != null) return principal;
    }

    return _firstMatch([
      RegExp(
        r'(?:has\s*been\s+)?credited(?:\s+by\s+[^.]+)?\s+with\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'credited\s+with\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false),
      _etbAmount,
    ], body);
  }

  static double _sumCbeFees(String body) {
    var total = 0.0;

    final serviceCharge = _firstMatch([
      RegExp(
        r'service\s+charge\s+of\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'service\s+charge\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);
    if (serviceCharge != null) total += serviceCharge;

    final vat = _firstMatch([
      RegExp(
        r'VAT\s*\([^)]*\)\s+of\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);
    if (vat != null) total += vat;

    final disasterRecovery = _firstMatch([
      RegExp(
        r'Disaster\s+Recovery\s*\([^)]*\)\s+of\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);
    if (disasterRecovery != null) total += disasterRecovery;

    return total;
  }

  // --- BOA -------------------------------------------------------------------

  static ParsedSmsTransaction? _parseBoa(String body) {
    final lower = body.toLowerCase();

    // POS lock/hold SMS is not a separate transaction — BOA also sends a
    // "was debited with ETB X" message for the same purchase.
    if (lower.contains('is locked from your account') &&
        lower.contains('pos transaction')) {
      return null;
    }

    final type = _detectType(lower, [
      _TypeRule(r'was debited', 'withdrawal'),
      _TypeRule(r'was credited', 'income'),
    ]);

    final amount = _firstMatch([
      RegExp(
        r'(?:was\s+)?debited\s+with\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:was\s+)?credited\s+with\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);

    final balance = _firstMatch([
      RegExp(
        r'available\s+balance\s*:?\s*ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'your\s+available\s+balance\s+is\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);

    return _build(type: type, amount: amount, balance: balance);
  }

  // --- telebirr (127) --------------------------------------------------------

  static ParsedSmsTransaction? _parse127(String body) {
    final lower = body.toLowerCase();
    final type = _detectType(lower, [
      _TypeRule(r'you have transferred', 'withdrawal'),
      _TypeRule(r'you have paid', 'withdrawal'),
      _TypeRule(r'you have recharged', 'withdrawal'),
      _TypeRule(r'you have withdrawn', 'withdrawal'),
      _TypeRule(r'cash out', 'withdrawal'),
      _TypeRule(r'you have received etb', 'income'),
      _TypeRule(r'you have received  etb', 'income'),
      _TypeRule(r'has been credited', 'income'),
    ]);

    final amount = _parse127Amount(body, type);
    final balance = _firstMatch([
      RegExp(
        r'e-money account\s+balance\s+is\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'your current\s+balance\s+is\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'your current\s+balance\s+is\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'available\s+balance\s*:?\s*ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);

    return _build(type: type, amount: amount, balance: balance);
  }

  static double? _parse127Amount(String body, String type) {
    if (type == 'withdrawal') {
      final transferred = _firstMatch([
        RegExp(
          r'you have transferred\s+ETB\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
      ], body);
      if (transferred != null) {
        return transferred + _sumTelebirrFees(body);
      }

      return _firstMatch([
        RegExp(
          r'you have paid\s+ETB\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
        RegExp(
          r'you have recharged\s+ETB\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
        RegExp(
          r'you have withdrawn\s+ETB\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
        _etbAmount,
      ], body);
    }

    return _firstMatch([
      RegExp(
        r'you have received\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:has\s*been\s+)?credited\s+with\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      _etbAmount,
    ], body);
  }

  static double _sumTelebirrFees(String body) {
    var total = 0.0;
    final serviceFee = _firstMatch([
      RegExp(
        r'service fee is\s+ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);
    if (serviceFee != null) total += serviceFee;

    final vat = _firstMatch([
      RegExp(
        r'VAT on the service fee is ETB\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);
    if (vat != null) total += vat;

    return total;
  }

  // --- M-PESA ----------------------------------------------------------------

  static ParsedSmsTransaction? _parseMpesa(String body) {
    final lower = body.toLowerCase();
    final type = _detectType(lower, [
      _TypeRule(r'you have sent', 'withdrawal'),
      _TypeRule(r'you have paid', 'withdrawal'),
      _TypeRule(r'you have bought', 'withdrawal'),
      _TypeRule(r'you have withdrawn', 'withdrawal'),
      _TypeRule(r'cashback of', 'income'),
      _TypeRule(r'you have received', 'income'),
    ]);

    final amount = _parseMpesaAmount(body, type);
    final balance = _firstMatch([
      RegExp(
        r'your\s+(?:new|current)\s+m-?pesa balance is\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'your\s+m-?pesa balance is\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'm-?pesa balance is\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ], body);

    return _build(
      type: type,
      amount: amount,
      balance: balance,
      currency: 'BIRR',
    );
  }

  static double? _parseMpesaAmount(String body, String type) {
    if (type == 'income') {
      return _firstMatch([
        RegExp(
          r'you have received(?:\s+\w+)+\s+of\s+([\d,]+\.?\d*)\s+birr',
          caseSensitive: false,
        ),
        RegExp(
          r'cashback of\s+([\d,]+\.?\d*)\s+birr',
          caseSensitive: false,
        ),
        RegExp(
          r'you have received\s+([\d,]+\.?\d*)\s+birr',
          caseSensitive: false,
        ),
      ], body);
    }

    var amount = _firstMatch([
      RegExp(
        r'you have sent\s+([\d,]+\.?\d*)\s+birr',
        caseSensitive: false,
      ),
      RegExp(
        r'you have paid\s+([\d,]+\.?\d*)\s+birr',
        caseSensitive: false,
      ),
      RegExp(
        r'you have bought\s+([\d,]+\.?\d*)\s+birr',
        caseSensitive: false,
      ),
      RegExp(
        r'you have withdrawn\s+([\d,]+\.?\d*)\s+birr',
        caseSensitive: false,
      ),
    ], body);

    final fee = _firstMatch([
      RegExp(
        r'transaction fee\s+([\d,]+\.?\d*)\s+birr',
        caseSensitive: false,
      ),
    ], body);

    if (amount != null && fee != null && fee > 0) {
      amount += fee;
    }
    return amount;
  }

  // --- shared ----------------------------------------------------------------

  static String _detectType(String lower, List<_TypeRule> rules) {
    for (final rule in rules) {
      if (lower.contains(rule.phrase)) return rule.type;
    }
    return 'unknown';
  }

  static double? _firstMatch(List<RegExp> patterns, String body) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (value != null) return value;
      }
    }
    return null;
  }

  static ParsedSmsTransaction? _build({
    required String type,
    required double? amount,
    required double? balance,
    String currency = 'ETB',
  }) {
    if (type == 'unknown' || amount == null || balance == null) {
      return null;
    }
    return ParsedSmsTransaction(
      transactionType: type,
      amount: amount,
      balance: balance,
      currency: currency,
    );
  }
}

class _TypeRule {
  const _TypeRule(this.phrase, this.type);
  final String phrase;
  final String type;
}
