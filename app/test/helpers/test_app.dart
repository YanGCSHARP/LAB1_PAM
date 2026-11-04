import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/app.dart';
import 'package:walletmate/core/data/mock/mock_providers.dart';
import 'package:walletmate/core/data/mock/mock_seed.dart';
import 'package:walletmate/core/state/clock.dart';

/// The day every test runs on. The demo data is laid out relative to "today",
/// so pinning it keeps the data — and the expectations — the same on any day.
final DateTime testToday = DateTime(2026, 9, 18);

/// The demo data as the app sees it on [testToday].
final MockSeed testSeed = MockSeed.relativeTo(testToday);

/// Pins "today" and sets the mock network delay — none by default.
List<Override> testOverrides({Duration latency = Duration.zero}) => [
  todayProvider.overrideWithValue(testToday),
  mockLatencyProvider.overrideWithValue(latency),
];

/// [child] under a [ProviderScope] configured like the app's, with
/// [testOverrides].
Widget withProviders(Widget child, {Duration latency = Duration.zero}) {
  return ProviderScope(
    retry: noRetry,
    overrides: testOverrides(latency: latency),
    child: child,
  );
}

/// A [ProviderContainer] for testing providers without widgets.
ProviderContainer createTestContainer() {
  final container = ProviderContainer(
    retry: noRetry,
    overrides: testOverrides(),
  );
  addTearDown(container.dispose);
  return container;
}

/// Pumps the whole app at [location] and waits for the data to load.
Future<void> pumpApp(
  WidgetTester tester,
  String location, {
  bool signedIn = true,
  Size size = const Size(420, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    withProviders(WalletMateApp(signedIn: signedIn, initialLocation: location)),
  );
  await tester.pumpAndSettle();
}

/// The provider container of the app pumped by [pumpApp], to inspect or
/// change state directly.
ProviderContainer appContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(WalletMateApp)));
