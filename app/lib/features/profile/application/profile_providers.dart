import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/cache/cached_repositories.dart';
import '../../../core/data/cache/data_cache.dart';
import '../../../core/data/mock/mock_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../data/api_profile_repository.dart';
import '../data/mock_profile_repository.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// The only place that decides which [ProfileRepository] the app uses: the
/// backend behind the offline cache, or the in-memory mock with `USE_MOCKS`
/// and in tests.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ref.watch(useMockBackendProvider)
      ? MockProfileRepository(ref.watch(mockBackendProvider))
      : CachedProfileRepository(
          ApiProfileRepository(ref.watch(apiClientProvider)),
          ref.watch(dataCacheProvider),
          ({required offline}) =>
              ref.read(offlineProvider.notifier).set(offline: offline),
        ),
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

  Future<void> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final updated = await ref
        .read(profileRepositoryProvider)
        .uploadAvatar(bytes: bytes, filename: filename, mimeType: mimeType);
    state = AsyncData(updated);
  }

  Future<void> _save(UserProfile Function(UserProfile profile) change) async {
    final current = await future;
    final updated = await ref
        .read(profileRepositoryProvider)
        .update(change(current));
    state = AsyncData(updated);
  }
}
