import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/mock/mock_data.dart';
import 'package:walletmate/core/router/app_router.dart';
import 'package:walletmate/core/router/app_routes.dart';
import 'package:walletmate/core/utils/category_catalog.dart';
import 'package:walletmate/features/transactions/domain/transaction_filter.dart';

void main() {
  group('authRedirect', () {
    test('signed out: private routes bounce to /login', () {
      for (final location in [
        AppRoutes.dashboard,
        AppRoutes.transaction('tx-01'),
        AppRoutes.accounts,
        '/no-such-page',
      ]) {
        expect(
          authRedirect(signedIn: false, location: location),
          AppRoutes.login,
          reason: location,
        );
      }
    });

    test('signed out: auth screens stay open', () {
      expect(authRedirect(signedIn: false, location: AppRoutes.login), isNull);
      expect(
        authRedirect(signedIn: false, location: AppRoutes.register),
        isNull,
      );
    });

    test('signed in: auth screens bounce to the dashboard', () {
      expect(
        authRedirect(signedIn: true, location: AppRoutes.login),
        AppRoutes.dashboard,
      );
      expect(
        authRedirect(signedIn: true, location: AppRoutes.register),
        AppRoutes.dashboard,
      );
    });

    test('signed in: private routes stay open', () {
      expect(authRedirect(signedIn: true, location: AppRoutes.budgets), isNull);
    });
  });

  group('AppRoutes', () {
    test('builds paths with ids', () {
      expect(AppRoutes.transaction('tx-01'), '/transactions/tx-01');
      expect(AppRoutes.transactionEdit('tx-01'), '/transactions/tx-01/edit');
      expect(AppRoutes.budgetEdit('bud-1'), '/budgets/bud-1/edit');
      expect(AppRoutes.accountEdit('acc-1'), '/accounts/acc-1/edit');
    });

    test('omits the query when there is nothing to put in it', () {
      expect(
        AppRoutes.transactionsFiltered(const TransactionFilter()),
        '/transactions',
      );
      expect(AppRoutes.budgetNew(), '/budgets/new');
      expect(
        AppRoutes.budgetNew(month: '2026-09'),
        '/budgets/new?month=2026-09',
      );
    });
  });

  group('TransactionFilter', () {
    test('round-trips through a URL', () {
      const filter = TransactionFilter(
        kind: TransactionKind.expense,
        category: 'food',
        month: '2026-09',
      );
      final uri = Uri.parse(AppRoutes.transactionsFiltered(filter));

      expect(uri.path, '/transactions');
      expect(TransactionFilter.fromQuery(uri.queryParameters), filter);
    });

    test('drops malformed values instead of failing', () {
      final filter = TransactionFilter.fromQuery({
        'type': 'refund',
        'month': '2026-13',
        'category': '',
      });
      expect(filter.isEmpty, isTrue);
    });

    test('filters by category and month', () {
      const filter = TransactionFilter(category: 'food', month: '2026-09');
      final result = filter.apply(mockTransactions);

      // tx-02, tx-06, tx-09, tx-13, tx-17 in the mock data.
      expect(result, hasLength(5));
      expect(result.every((t) => t.category == 'food'), isTrue);
      // Newest first.
      expect(result.first.id, 'tx-17');
    });

    test('filters by type', () {
      const filter = TransactionFilter(kind: TransactionKind.income);
      final result = filter.apply(mockTransactions);

      expect(result, isNotEmpty);
      expect(result.every((t) => t.isIncome), isTrue);
    });

    test('searches the note and the category label, ignoring case', () {
      expect(
        const TransactionFilter(query: 'АРЕНДА').apply(mockTransactions),
        hasLength(2),
      );
      // "Здоровье" is the label of `health`; the note says "Аптека".
      expect(
        const TransactionFilter(query: 'здоров')
            .apply(mockTransactions)
            .single
            .id,
        'tx-11',
      );
    });

    test('counts only chip filters as active', () {
      const filter = TransactionFilter(category: 'food', query: 'кофе');
      expect(filter.activeCount, 1);
    });
  });
}
