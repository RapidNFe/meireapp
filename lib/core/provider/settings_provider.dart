import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool isCompact;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.isCompact = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? isCompact,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isCompact: isCompact ?? this.isCompact,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState());

  void toggleTheme() {
    state = state.copyWith(
      themeMode:
          state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void toggleCompact() {
    state = state.copyWith(isCompact: !state.isCompact);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
