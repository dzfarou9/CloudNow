import 'package:flutter/material.dart';

import 'palette.dart';

/// Direct port of the type/layout/motion ramp in `DesktopTokens.qml`.
abstract final class OpenNowTokens {
  static const double titleSize = 26;
  static const double headingSize = 17;
  static const double bodySize = 15;
  static const double captionSize = 13;
  static const double monoSize = 12;
  static const double smallSize = 11;
  static const double microSize = 10;
  static const double tinySize = 9;

  static const double railWidth = 232;
  static const double railCollapsedWidth = 72;
  static const double topBarHeight = 64;
  static const double statusBarHeight = 52;
  static const double rowHeight = 60;
  static const double controlHeight = 38;
  static const double settingsInset = 20;
  static const double posterWidth = 112;
  static const double posterHeight = 168;
  static const double libraryCellWidth = 146;
  static const double libraryCellHeight = 214;

  static const Duration quickDuration = Duration(milliseconds: 120);
  static const Duration motionDuration = Duration(milliseconds: 220);
  static const Duration revealDuration = Duration(milliseconds: 320);

  static const String displayFont = 'Nunito';
  static const String bodyFont = 'Nunito';
  static const String monoFont = 'IBM Plex Mono';

  /// Mirrors DesktopTokens.scaleForWindow: use reflow, not aggressive scaling.
  static double scaleForWindow(Size size) =>
      (size.width / 1440 < size.height / 900
              ? size.width / 1440
              : size.height / 900)
          .clamp(0.95, 1.15);
}

/// Builds the Material theme for one of the eight OpenNOW theme packs.
ThemeData openNowThemeData({
  required ThemePack pack,
  required bool light,
  String accent = 'blue',
  bool accentOverridden = false,
  bool translucent = false,
}) {
  final shell = colorOf(pack.shellFor(light));
  final focus = accentOverridden
      ? colorOf(
          light
              ? (lightAccents[accent] ?? lightAccents['blue']!)
              : (darkAccents[accent] ?? darkAccents['blue']!),
        )
      : colorOf(pack.accentFor(light));
  final label = light ? colorOf('#111827') : const Color(0xFFFFFFFF);
  final muted = light
      ? colorOf('#111827').withValues(alpha: 0.64)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.64);
  final seam = light
      ? colorOf('#0A0F1A').withValues(alpha: 0.14)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.14);
  final surface = shell.withValues(alpha: translucent ? 0.52 : 0.72);
  final raised = light
      ? colorOf('#0A0F1A').withValues(alpha: 0.08)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.08);

  final base = ThemeData(
    useMaterial3: true,
    brightness: light ? Brightness.light : Brightness.dark,
    colorScheme: ColorScheme(
      brightness: light ? Brightness.light : Brightness.dark,
      primary: focus,
      onPrimary: contrastText(focus),
      secondary: colorOf('#56E6A5'),
      onSecondary: colorOf('#111827'),
      surface: surface,
      onSurface: label,
      surfaceContainerHighest: raised,
      error: colorOf('#FF8A80'),
      onError: colorOf('#111827'),
      outline: seam,
    ),
    scaffoldBackgroundColor: shell,
    fontFamily: OpenNowTokens.bodyFont,
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontFamily: OpenNowTokens.displayFont,
        fontSize: OpenNowTokens.titleSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: label,
      ),
      titleLarge: TextStyle(
        fontFamily: OpenNowTokens.displayFont,
        fontSize: OpenNowTokens.headingSize,
        fontWeight: FontWeight.w700,
        color: label,
      ),
      titleMedium: TextStyle(
        fontSize: OpenNowTokens.bodySize,
        fontWeight: FontWeight.w700,
        color: label,
      ),
      bodyLarge: TextStyle(fontSize: OpenNowTokens.bodySize, color: label),
      bodyMedium: TextStyle(fontSize: OpenNowTokens.captionSize, color: label),
      bodySmall: TextStyle(fontSize: OpenNowTokens.smallSize, color: muted),
      labelSmall: TextStyle(
        fontFamily: OpenNowTokens.monoFont,
        fontSize: OpenNowTokens.monoSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.45,
        color: muted,
      ),
    ),
    iconTheme: IconThemeData(color: label, size: 18),
    dividerColor: seam,
    cardColor: surface,
    dialogTheme: DialogThemeData(backgroundColor: shell),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: shell.withValues(alpha: 0.9),
      indicatorColor: focus.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontSize: OpenNowTokens.smallSize, color: label),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: shell.withValues(alpha: 0.9),
      selectedIconTheme: IconThemeData(color: focus),
      unselectedIconTheme: IconThemeData(color: muted),
      minWidth: OpenNowTokens.railCollapsedWidth,
    ),
  );

  return base.copyWith(
    extensions: [
      OpenNowColors(
        shell: shell,
        surface: surface,
        raised: raised,
        seam: seam,
        label: label,
        muted: muted,
        focus: focus,
        focusText: contrastText(focus),
        mint: colorOf('#56E6A5'),
        amber: colorOf('#FFD166'),
        danger: colorOf('#FF8A80'),
      ),
    ],
  );
}

/// Tokens that have no direct Material role, exposed as a ThemeExtension so
/// widgets can read them without threading colors through every constructor.
class OpenNowColors extends ThemeExtension<OpenNowColors> {
  const OpenNowColors({
    required this.shell,
    required this.surface,
    required this.raised,
    required this.seam,
    required this.label,
    required this.muted,
    required this.focus,
    required this.focusText,
    required this.mint,
    required this.amber,
    required this.danger,
  });

  final Color shell;
  final Color surface;
  final Color raised;
  final Color seam;
  final Color label;
  final Color muted;
  final Color focus;
  final Color focusText;
  final Color mint;
  final Color amber;
  final Color danger;

  static OpenNowColors of(BuildContext context) =>
      Theme.of(context).extension<OpenNowColors>()!;

  @override
  OpenNowColors copyWith({
    Color? shell,
    Color? surface,
    Color? raised,
    Color? seam,
    Color? label,
    Color? muted,
    Color? focus,
    Color? focusText,
    Color? mint,
    Color? amber,
    Color? danger,
  }) => OpenNowColors(
    shell: shell ?? this.shell,
    surface: surface ?? this.surface,
    raised: raised ?? this.raised,
    seam: seam ?? this.seam,
    label: label ?? this.label,
    muted: muted ?? this.muted,
    focus: focus ?? this.focus,
    focusText: focusText ?? this.focusText,
    mint: mint ?? this.mint,
    amber: amber ?? this.amber,
    danger: danger ?? this.danger,
  );

  @override
  OpenNowColors lerp(OpenNowColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return OpenNowColors(
      shell: mix(shell, other.shell),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      seam: mix(seam, other.seam),
      label: mix(label, other.label),
      muted: mix(muted, other.muted),
      focus: mix(focus, other.focus),
      focusText: mix(focusText, other.focusText),
      mint: mix(mint, other.mint),
      amber: mix(amber, other.amber),
      danger: mix(danger, other.danger),
    );
  }
}
