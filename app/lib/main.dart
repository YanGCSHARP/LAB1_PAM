import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/utils/formatters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Russian month and weekday names for DateFormat.
  await initializeDateFormatting(Formatters.locale);
  runApp(
    const ProviderScope(
      // Riverpod retries a failed load on its own for half a minute by
      // default, showing a spinner all that time. A failure is reported at
      // once instead, and the error state offers «Повторить».
      retry: noRetry,
      child: WalletMateApp(),
    ),
  );
}
