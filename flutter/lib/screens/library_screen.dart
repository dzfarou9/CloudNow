import 'package:flutter/material.dart';

import '../core/models.dart';
import '../state/shell_scope.dart';
import '../widgets/game_card.dart';
import '../widgets/game_modal.dart';

/// Port of `DesktopLibraryScreen.qml`: searchable/filterable 2:3 poster grid.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.query = ''});

  final String query;

  static const List<String> filters = [
    'All',
    'Favorites',
    'Available versions',
    'RTX',
    'Controller',
    'Steam',
    'Epic',
    'GOG',
    'Hidden',
  ];

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final store = ShellScope.of(context);
    final games = _applyFilter(store.library, _filter, widget.query);

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: LibraryScreen.filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => FilterChip(
              label: Text(LibraryScreen.filters[index]),
              selected: _filter == index,
              onSelected: (_) => setState(() => _filter = index),
            ),
          ),
        ),
        Expanded(
          child: games.isEmpty
              ? const Center(child: Text('No games match this filter'))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 146 / 214,
                  ),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return GameCard(
                      game: game,
                      width: 146,
                      onTap: () => showGameModal(context, store, game),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static List<Game> _applyFilter(List<Game> games, int filter, String query) {
    var result = games
        .where(
          (game) => query.isEmpty || game.name.toLowerCase().contains(query),
        )
        .toList();
    switch (filter) {
      case 1:
        result = result.where((game) => game.favorite).toList();
      case 2:
        result = result.where((game) => game.variantId != null).toList();
      case 8:
        result = <Game>[];
    }
    return result;
  }
}
