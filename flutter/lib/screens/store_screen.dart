import 'package:flutter/material.dart';

import '../core/models.dart';
import '../state/shell_scope.dart';
import '../widgets/game_card.dart';
import '../widgets/game_modal.dart';

/// Port of `DesktopStoreContent.qml`: hero marquee, New/Popular shelves and
/// category filters. The desktop auto-advances its hero every 6 s.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.query = ''});

  final String query;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final int _slide = 0;
  String _category = 'All';
  static const categories = ['All', 'Games', 'Actions', 'Steam', 'Epic'];

  @override
  Widget build(BuildContext context) {
    final store = ShellScope.of(context);
    final games = store.featured.isEmpty ? store.library : store.featured;
    final visible = games
        .where(
          (game) =>
              widget.query.isEmpty ||
              game.name.toLowerCase().contains(widget.query.toLowerCase()),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        if (visible.isNotEmpty)
          _Marquee(game: visible[_slide % visible.length]),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ChoiceChip(
              label: Text(categories[index]),
              selected: _category == categories[index],
              onSelected: (_) => setState(() => _category = categories[index]),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _Shelf(
          title: 'NEW',
          games: visible,
          onOpen: (game) => showGameModal(context, store, game),
        ),
        const SizedBox(height: 24),
        _Shelf(
          title: 'POPULAR',
          games: visible.reversed.toList(),
          onOpen: (game) => showGameModal(context, store, game),
        ),
      ],
    );
  }
}

class _Marquee extends StatelessWidget {
  const _Marquee({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.65),
              colors.surfaceContainerHighest,
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('FEATURED', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(game.name, style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.title,
    required this.games,
    required this.onOpen,
  });

  final String title;
  final List<Game> games;
  final void Function(Game game) onOpen;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 112,
              child: GameCard(
                game: games[index],
                width: 112,
                onTap: () => onOpen(games[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
