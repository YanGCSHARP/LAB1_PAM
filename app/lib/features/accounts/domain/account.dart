import 'package:equatable/equatable.dart';

import '../../../core/utils/money.dart';

/// Account type — decides the icon and tint of an account card.
enum AccountKind { card, cash, savings }

/// A place money is kept: a bank card, cash, savings.
///
/// The balance is not a field: it is derived from [openingBalance] and the
/// account's transactions (see [AccountBalance]), so an operation can never
/// "forget" to update it.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.currency,
    this.kind = AccountKind.card,
    this.openingBalance = 0,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    currency: json['currency'] as String,
    kind: AccountKind.values.asNameMap()[json['kind']] ?? AccountKind.card,
    openingBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
  );

  final String id;

  /// 1–50 characters, unique among the user's accounts.
  final String name;

  /// ISO-4217 code: `MDL`, `EUR`, `USD`.
  final String currency;

  final AccountKind kind;

  /// Balance the account was opened with (`initialBalance` in the API).
  /// May be negative — a credit card can start in debt.
  final double openingBalance;

  Account copyWith({
    String? name,
    String? currency,
    AccountKind? kind,
    double? openingBalance,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      kind: kind ?? this.kind,
      openingBalance: openingBalance ?? this.openingBalance,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'currency': currency,
    'kind': kind.name,
    'initialBalance': Money.round(openingBalance),
  };

  @override
  List<Object?> get props => [id, name, currency, kind, openingBalance];
}

/// An account together with its current balance.
class AccountBalance extends Equatable {
  const AccountBalance({required this.account, required this.balance});

  final Account account;
  final double balance;

  @override
  List<Object?> get props => [account, balance];
}
