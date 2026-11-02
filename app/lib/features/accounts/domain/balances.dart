import '../../../core/utils/money.dart';
import '../../transactions/domain/transaction.dart';
import 'account.dart';

/// Current balance of every account, in the order of [accounts]:
/// `openingBalance + Σ income − Σ expense` over the account's transactions.
List<AccountBalance> computeBalances(
  List<Account> accounts,
  Iterable<Transaction> transactions,
) {
  final movements = <String, List<double>>{};
  for (final transaction in transactions) {
    (movements[transaction.accountId] ??= []).add(transaction.signedAmount);
  }
  return [
    for (final account in accounts)
      AccountBalance(
        account: account,
        balance: Money.sum([account.openingBalance, ...?movements[account.id]]),
      ),
  ];
}

/// Balances summed per currency, in the order currencies first appear.
/// Accounts in different currencies are never added together.
Map<String, double> totalsByCurrency(Iterable<AccountBalance> balances) {
  final grouped = <String, List<double>>{};
  for (final item in balances) {
    (grouped[item.account.currency] ??= []).add(item.balance);
  }
  return grouped.map(
    (currency, amounts) => MapEntry(currency, Money.sum(amounts)),
  );
}

/// The [transactions] made on accounts in [currency] — the only ones that can
/// be summed into a total in that currency.
List<Transaction> transactionsInCurrency(
  Iterable<Transaction> transactions,
  Iterable<Account> accounts,
  String currency,
) {
  final ids = {
    for (final account in accounts)
      if (account.currency == currency) account.id,
  };
  return [
    for (final transaction in transactions)
      if (ids.contains(transaction.accountId)) transaction,
  ];
}
