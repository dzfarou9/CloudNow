import 'dart:math' as math;
import 'dart:ui';

/// Direct port of `opennow-qt/qml/theme/Theme.qml`. Keep the hex values in sync
/// with the desktop packs: the Android client should look like the same app.
class ThemePack {
  const ThemePack({
    required this.id,
    required this.name,
    required this.detail,
    required this.category,
    required this.bg,
    this.lightBg,
    this.darkBg,
    required this.mid,
    required this.accent,
    this.lightAccent,
    this.darkAccent,
  });

  final String id;
  final String name;
  final String detail;
  final String category;
  final String bg;
  final String? lightBg;
  final String? darkBg;
  final String mid;
  final String accent;
  final String? lightAccent;
  final String? darkAccent;

  bool get isLight => category == 'Light';

  String shellFor(bool light) => light ? (lightBg ?? bg) : (darkBg ?? bg);
  String accentFor(bool light) =>
      light ? (lightAccent ?? accent) : (darkAccent ?? accent);
}

const List<ThemePack> themePacks = [
  ThemePack(
    id: 'nocturne',
    name: 'Nocturne',
    detail: 'SKY GLASS',
    category: 'Dark',
    bg: '#0B0F1A',
    lightBg: '#EEF3FA',
    mid: '#252A48',
    accent: '#7FD4FF',
    lightAccent: '#12638C',
  ),
  ThemePack(
    id: 'aurora',
    name: 'Aurora',
    detail: 'MINT AURORA',
    category: 'Dark',
    bg: '#071A20',
    lightBg: '#EAF5F2',
    mid: '#16434A',
    accent: '#6EE7B7',
    lightAccent: '#126B4E',
  ),
  ThemePack(
    id: 'kraft',
    name: 'Kraft',
    detail: 'WARM BRASS',
    category: 'Dark',
    bg: '#211D17',
    lightBg: '#F4ECDD',
    mid: '#756346',
    accent: '#D3A85C',
    lightAccent: '#796020',
  ),
  ThemePack(
    id: 'phosphor',
    name: 'Phosphor',
    detail: 'CRT GLOW',
    category: 'High contrast',
    bg: '#07120B',
    lightBg: '#EDF8EA',
    mid: '#12351D',
    accent: '#6BFF8A',
    lightAccent: '#216C31',
  ),
  ThemePack(
    id: 'bone',
    name: 'Bone',
    detail: 'WARM MINIMAL',
    category: 'Light',
    bg: '#EEE7DB',
    darkBg: '#201D18',
    mid: '#A89578',
    accent: '#7F6A4D',
    darkAccent: '#D3BA91',
  ),
  ThemePack(
    id: 'cobalt',
    name: 'Cobalt',
    detail: 'COBALT PAPER',
    category: 'Light',
    bg: '#F7F9FF',
    darkBg: '#0E1730',
    mid: '#ADC4FF',
    accent: '#245BDB',
    darkAccent: '#93B5FF',
  ),
  ThemePack(
    id: 'hibiscus',
    name: 'Hibiscus',
    detail: 'ROSE GLASS',
    category: 'Dark',
    bg: '#1F0C18',
    lightBg: '#FAEDF3',
    mid: '#642343',
    accent: '#FF6F9F',
    lightAccent: '#AA285B',
  ),
  ThemePack(
    id: 'chapel',
    name: 'Chapel',
    detail: 'GOLD GLASS',
    category: 'Dark',
    bg: '#151225',
    lightBg: '#F3EFF9',
    mid: '#40355D',
    accent: '#FFD166',
    lightAccent: '#806017',
  ),
];

ThemePack packById(String id) => themePacks.firstWhere(
  (pack) => pack.id == id,
  orElse: () => themePacks.first,
);

const Map<String, String> darkAccents = {
  'green': '#6EE7B7',
  'blue': '#7FD4FF',
  'violet': '#A78BFA',
  'rose': '#FF8A9A',
  'coral': '#FF8A80',
  'amber': '#FFD166',
  'white': '#FFFFFF',
};

const Map<String, String> lightAccents = {
  'green': '#126B4E',
  'blue': '#12638C',
  'violet': '#7042BA',
  'rose': '#AA285B',
  'coral': '#A9362C',
  'amber': '#806017',
  'white': '#374151',
};

const List<String> accentChoices = [
  'green',
  'blue',
  'violet',
  'rose',
  'coral',
  'amber',
  'white',
];

Color colorOf(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

/// Port of Theme.contrastText: WCAG luminance comparison, returns #111827 or white.
Color contrastText(Color background) {
  double linear(int channel) {
    final value = channel / 255;
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  final luminance =
      linear((background.r * 255).round()) * 0.2126 +
      linear((background.g * 255).round()) * 0.7152 +
      linear((background.b * 255).round()) * 0.0722;
  final contrastWithDark = (luminance + 0.05) / (0.0196 + 0.05);
  final contrastWithLight = (1.05) / (luminance + 0.05);
  return contrastWithDark > contrastWithLight
      ? colorOf('#111827')
      : const Color(0xFFFFFFFF);
}
