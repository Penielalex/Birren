import 'dart:io';

import 'package:birren/data/service/sms_regex_parser.dart';

/// Validates parser against sms_logs/*.md captured from device.
void main() {
  final logDir = Directory('sms_logs');
  if (!logDir.existsSync()) {
    stderr.writeln('Run from repo root with sms_logs/ present.');
    exit(1);
  }

  for (final bank in ['CBE', 'BOA', '127', 'MPESA']) {
    final file = File('sms_logs/${bank}_sms_log.md');
    if (!file.existsSync()) continue;

    final text = file.readAsStringSync();
    final bodies = _extractBodies(text);
    var parsed = 0;
    var failed = 0;

    for (final body in bodies) {
      final result = SmsRegexParser.parse(bank: bank, body: body);
      if (result != null && result.isActionable) {
        parsed++;
      } else {
        failed++;
      }
    }

    stdout.writeln(
      '$bank: ${bodies.length} messages | $parsed parsed | $failed not actionable',
    );
  }
}

List<String> _extractBodies(String markdown) {
  final normalized = markdown.replaceAll('\r\n', '\n');
  final bodies = <String>[];
  final pattern = RegExp(r'```text\n(.*?)```', dotAll: true);
  for (final match in pattern.allMatches(normalized)) {
    bodies.add(match.group(1)!.trim());
  }
  return bodies;
}
