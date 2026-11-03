import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/mock/mock_providers.dart';
import '../data/mock_profile_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// The only place that decides which [ProfileRepository] the app uses.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(ref.watch(mockBackendProvider)),
);

/// The signed-in user. Its default currency drives the dashboard totals and
/// the budgets, so changing it re-computes both.
final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() {
    return ref.watch(profileRepositoryProvider).fetch();
  }

  Future<void> rename(String displayName) =>
      _save((profile) => profile.copyWith(displayName: displayName));

  Future<void> changeCurrency(String currency) =>
      _save((profile) => profile.copyWith(defaultCurrency: currency));

  Future<void> _save(UserProfile Function(UserProfile profile) change) async {
    final current = await future;
    final updated = await ref
        .read(profileRepositoryProvider)
        .update(change(current));
    state = AsyncData(updated);
  }
}
