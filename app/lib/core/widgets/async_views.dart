import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../features/home/application/data_refresh.dart';
import '../data/repository_exception.dart';
import '../router/not_found_screen.dart';
import 'state_views.dart';

/// Title of every "could not load" state.
const String loadErrorTitle = 'Не удалось загрузить данные';

/// The body of a screen backed by an [AsyncValue]: [loading] while the first
/// load is in flight, an [ErrorState] with «Повторить» on failure, [data]
/// otherwise.
///
/// A reload keeps showing the previous data (Riverpod's default), so pull to
/// refresh does not blank the screen.
class AsyncValueView<T> extends ConsumerWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    super.key,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Defaults to a centered spinner; screens pass a skeleton of their shape.
  final Widget? loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      data: data,
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        title: loadErrorTitle,
        message: errorMessage(error),
        onRetry: () => refreshAllData(ref),
      ),
    );
  }
}

/// A routed page for one record — `/transactions/:id`, `/accounts/:id/edit`.
///
/// Waits for [provider], shows [NotFoundScreen] when it resolves to `null`
/// (a stale or mistyped link), and builds the page otherwise.
///
/// Once a record has been shown it stays on screen even if it disappears from
/// the data: deleting it from this very page pops the page, and the closing
/// animation must not flash "not found".
class RecordPage<T extends Object> extends ConsumerStatefulWidget {
  const RecordPage({required this.provider, required this.builder, super.key});

  final ProviderListenable<AsyncValue<T?>> provider;
  final Widget Function(BuildContext context, T record) builder;

  @override
  ConsumerState<RecordPage<T>> createState() => _RecordPageState<T>();
}

class _RecordPageState<T extends Object> extends ConsumerState<RecordPage<T>> {
  T? _shown;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(widget.provider);
    final record = value.value ?? _shown;

    if (record != null) {
      _shown = record;
      return widget.builder(context, record);
    }
    if (value.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          title: loadErrorTitle,
          message: errorMessage(value.error!),
          onRetry: () => refreshAllData(ref),
        ),
      );
    }
    if (value.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return const NotFoundScreen();
  }
}
