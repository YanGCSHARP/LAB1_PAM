import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/utils/formatters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Russian month and weekday names for DateFormat.
  await initializeDateFormatting(Formatters.locale);
  runApp(const WalletMateApp());
}
