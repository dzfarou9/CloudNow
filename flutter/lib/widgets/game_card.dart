import 'package:flutter/material.dart';

import '../core/models.dart';
import '../theme/opennow_theme.dart';

/// Flutter counterpart of `DesktopPoster.qml`: 2:3 artwork tile with a
/// deterministic gradient fallback while catalog artwork is unavailable.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    this.onTap,
    this.width = OpenNowTokens.libraryCellWidth,
    this.hero = false,
  });

  final Game game;
  final VoidCallback? onTap;
  final double width;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final colors = OpenNowColors.of(context);
    final height = hero ? width * 0.56 : width * 1.5;
    final palette = _paletteFor(game.id);

    return Semantics(
      label: '${game.name}, ${game.genre ?? 'game'}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: OpenNowTokens.quickDuration,
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.seam),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (game.artworkUrl case final url?)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: hero ? 20 : 14,
                      ),
                    ),
                    if (game.genre != null)
                      Text(
                        game.genre!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
              if (game.favorite || game.pinned)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    game.pinned ? Icons.push_pin : Icons.favorite,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mirrors the deterministic account-tile palette in DesktopAccountTile.qml.
  static List<Color> _paletteFor(String id) {
    const palettes = [
      [Color(0xFFFFD166), Color(0xFFFF8A80)],
      [Color(0xFFFF6F9F), Color(0xFFA78BFA)],
      [Color(0xFF93B5FF), Color(0xFF235BDB)],
      [Color(0xFF6DE7B7), Color(0xFF7FD4FF)],
    ];
    final hash = id.codeUnits.fold<int>(0, (sum, char) => sum + char);
    return palettes[hash % palettes.length];
  }
}
