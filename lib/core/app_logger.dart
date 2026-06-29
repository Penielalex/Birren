import 'package:logger/logger.dart';

export 'package:logger/logger.dart' show Logger;

const _prefix = '[MYAPP]';

final Logger appLogger = Logger(
  printer: PrefixPrinter(
    SimplePrinter(),
    debug: _prefix,
    trace: _prefix,
    info: _prefix,
    warning: _prefix,
    error: _prefix,
    fatal: _prefix,
  ),
);
