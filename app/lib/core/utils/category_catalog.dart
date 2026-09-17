import 'package:flutter/material.dart';

/// Transaction direction.
enum TransactionKind { income, expense }

/// A single entry of the built-in category dictionary.
@immutable
class CategoryInfo {
  const CategoryInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.kind,
  });

  /// Stable English key stored with the transaction.
  final String key;

  /// Russian label shown in the UI.
  final String label;

  final IconData icon;
  final TransactionKind kind;
}

/// The category dictionary from the project specification.
///
/// Keys stay in English so that adding Romanian or English labels later does
/// not require touching stored data.
abstract final class CategoryCatalog {
  static const List<CategoryInfo> expenses = [
    CategoryInfo(
      key: 'food',
      label: 'Еда',
      icon: Icons.restaurant_outlined,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'transport',
      label: 'Транспорт',
      icon: Icons.directions_bus_outlined,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'housing',
      label: 'Жильё',
      icon: Icons.home_outlined,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'utilities',
      label: 'Коммунальные',
      icon: Icons.bolt_outlined,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'health',
      label: 'Здоровье',
      icon: Icons.favorite_outline,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'education',
      label: 'Образование',
      icon: Icons.school_outlined,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'entertainment',
      label: 'Развлечения',
      icon: Icons.local_activity_outlined,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'shopping',
      label: 'Покупки',
      icon: Icons.shopping_bag_outlined,
      kind: TransactionKind.expense,
    ),
    CategoryInfo(
      key: 'other',
      label: 'Другое',
      icon: Icons.more_horiz,
      kind: TransactionKind.expense,
    ),
  ];

  static const List<CategoryInfo> incomes = [
    CategoryInfo(
      key: 'salary',
      label: 'Зарплата',
      icon: Icons.payments_outlined,
      kind: TransactionKind.income,
    ),
    CategoryInfo(
      key: 'scholarship',
      label: 'Стипендия',
      icon: Icons.school_outlined,
      kind: TransactionKind.income,
    ),
    CategoryInfo(
      key: 'freelance',
      label: 'Подработка',
      icon: Icons.laptop_mac_outlined,
      kind: TransactionKind.income,
    ),
    CategoryInfo(
      key: 'gift',
      label: 'Подарок',
      icon: Icons.card_giftcard_outlined,
      kind: TransactionKind.income,
    ),
    CategoryInfo(
      key: 'other',
      label: 'Другое',
      icon: Icons.more_horiz,
      kind: TransactionKind.income,
    ),
  ];

  /// Categories available for the given direction.
  static List<CategoryInfo> forKind(TransactionKind kind) =>
      kind == TransactionKind.income ? incomes : expenses;

  static const CategoryInfo _fallback = CategoryInfo(
    key: 'other',
    label: 'Другое',
    icon: Icons.more_horiz,
    kind: TransactionKind.expense,
  );

  /// Looks a category up by key, preferring the entry of the matching kind.
  static CategoryInfo byKey(String key, {TransactionKind? kind}) {
    final pool = kind == null ? [...expenses, ...incomes] : forKind(kind);
    for (final category in pool) {
      if (category.key == key) {
        return category;
      }
    }
    return _fallback;
  }

  /// Russian label for a category key.
  static String labelOf(String key, {TransactionKind? kind}) =>
      byKey(key, kind: kind).label;
}
