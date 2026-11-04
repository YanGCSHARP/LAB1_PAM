import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/clock.dart';
import 'mock_backend.dart';
import 'mock_seed.dart';

/// Delay of every mock request. Tests set it to zero.
final mockLatencyProvider = Provider<Duration>(
  (ref) => MockBackend.defaultLatency,
);

/// Debug switch on the profile screen: while on, every mock request fails
/// with a network error — the way to see the error states on a demo.
final simulateOfflineProvider = NotifierProvider<SimulateOfflineNotifier, bool>(
  SimulateOfflineNotifier.new,
);

class SimulateOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool offline}) => state = offline;
}

/// The single in-memory backend every mock repository shares — shared so that
/// deleting an account in one repository removes its operations in another.
final mockBackendProvider = Provider<MockBackend>((ref) {
  return MockBackend(
    seed: MockSeed.relativeTo(ref.watch(todayProvider)),
    latency: ref.watch(mockLatencyProvider),
    isOffline: () => ref.read(simulateOfflineProvider),
  );
});
