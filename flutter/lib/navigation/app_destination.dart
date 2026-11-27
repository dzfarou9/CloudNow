import 'package:flutter/material.dart';

/// Mirrors the desktop shell's sidebar destinations. The stream screen is a
/// separate surface: it must never replace the video item while overlays open.
enum AppDestination {
  home(0, 'Home', Icons.home_outlined, Icons.home),
  library(1, 'Library', Icons.video_library_outlined, Icons.video_library),
  store(2, 'Store', Icons.storefront_outlined, Icons.storefront),
  friends(3, 'Friends', Icons.people_outline, Icons.people),
  updates(4, 'Updates', Icons.system_update_outlined, Icons.system_update),
  settings(5, 'Settings', Icons.settings_outlined, Icons.settings);

  const AppDestination(this.navIndex, this.label, this.icon, this.selectedIcon);

  /// `index` is reserved by Enum, so the desktop's index is named `navIndex`.
  final int navIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  static AppDestination fromIndex(int index) =>
      AppDestination.values.firstWhere(
        (destination) => destination.navIndex == index,
        orElse: () => AppDestination.home,
      );
}
