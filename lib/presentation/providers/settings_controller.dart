import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/local/hive_service.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.currencySymbol = 'R\$',
  });

  final ThemeMode themeMode;
  final String currencySymbol;

  SettingsState copyWith({ThemeMode? themeMode, String? currencySymbol}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
      );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final box = HiveService.settings;
    final themeIndex = box.get('themeMode', defaultValue: 0) as int;
    final currency = box.get('currency', defaultValue: 'R\$') as String;
    Formatters.currencySymbol = currency;
    return SettingsState(
      themeMode: ThemeMode.values[themeIndex],
      currencySymbol: currency,
    );
  }

  void setThemeMode(ThemeMode mode) {
    HiveService.settings.put('themeMode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  void setCurrency(String symbol) {
    Formatters.currencySymbol = symbol;
    HiveService.settings.put('currency', symbol);
    state = state.copyWith(currencySymbol: symbol);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
