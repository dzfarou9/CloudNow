import 'package:flutter/material.dart';

import '../core/models.dart';
import '../state/shell_scope.dart';
import '../theme/opennow_theme.dart';
import '../widgets/game_card.dart';
import '../widgets/game_modal.dart';

/// Port of `DesktopHomeScreen.qml`: hero for the most recently played game and
/// three poster rails (Jump back in, Favorites, New).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    final store = ShellScope.of(context);
    final games = _filtered(store.library, query);
    final hero = games.isEmpty ? null : games.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        if (hero != null) ...[
          _Hero(game: hero, onPlay: () => store.launch(hero)),
          const SizedBox(height: 28),
        ],
        _Rail(
          title: 'JUMP BACK IN',
          games: store.recent.where((game) => _matches(game, query)).toList(),
          onOpen: (game) => showGameModal(context, store, game),
        ),
        const SizedBox(height: 24),
        _Rail(
          title: 'FAVORITES',
          games: games.where((game) => game.favorite).take(12).toList(),
          onOpen: (game) => showGameModal(context, store, game),
        ),
        const SizedBox(height: 24),
        _Rail(
          title: 'NEW',
          games: games.skip(2).take(12).toList(),
          onOpen: (game) => showGameModal(context, store, game),
        ),
        if (store.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              store.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  static bool _matches(Game game, String query) =>
      query.isEmpty || game.name.toLowerCase().contains(query);

  static List<Game> _filtered(List<Game> games, String query) =>
      games.where((game) => _matches(game, query)).toList();
}

class _Hero extends StatelessWidget {
  const _Hero({required this.game, required this.onPlay});

  final Game game;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [colors.primary.withValues(alpha: 0.55), colors.surface],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'START LAST GAME',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(game.name, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.title, required this.games, required this.onOpen});

  final String title;
  final List<Game> games;
  final void Function(Game game) onOpen;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: OpenNowTokens.libraryCellHeight + 8,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                GameCard(game: games[index], onTap: () => onOpen(games[index])),
          ),
        ),
      ],
    );
  }
}
