import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:walletmate/app.dart';
import 'package:walletmate/core/utils/formatters.dart';

/// Every routed screen, opened by its URL on the narrowest supported phone.
const List<String> _locations = [
  '/register',
  '/transactions',
  '/transactions?type=expense&category=food&month=2026-09',
  '/transactions/tx-05',
  '/transactions/new',
  '/transactions/tx-02/edit',
  '/budgets',
  '/budgets/new',
  '/budgets/bud-1/edit',
  '/profile',
  '/accounts',
  '/accounts/acc-1/edit',
  '/no-such-page',
];

void main() {
  setUpAll(() => initializeDateFormatting(Formatters.locale));

  for (final location in _locations) {
    for (final brightness in Brightness.values) {
      testWidgets('$location fits 360 px in ${brightness.name} theme', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 690);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          WalletMateApp(
            signedIn: location != '/register',
            initialLocation: location,
          ),
        );
        await tester.pumpAndSettle();

        // Scroll whatever scrolls, so overflow further down surfaces too.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.last, const Offset(0, -900));
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });
    }
  }
}
