import 'package:flutter/material.dart';

import '../core/models.dart';
import '../navigation/app_destination.dart';
import '../screens/auth_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/store_screen.dart';
import '../screens/updates_screen.dart';
import '../state/shell_scope.dart';
import '../state/shell_store.dart';
import '../stream/stream_screen.dart';
import '../theme/opennow_theme.dart';

/// Counterpart of `DesktopShell.qml` + `DesktopSidebar.qml`. On phones the
/// sidebar collapses to a bottom bar; the stream surface is always stacked
/// above the shell so overlays never recreate it.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ShellScope.of(context),
      builder: (context, _) {
        final store = ShellScope.of(context);
        if (!store.busy && store.account == null) {
          return const Scaffold(body: AuthScreen());
        }
        final destination = AppDestination.fromIndex(store.destination);

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return Stack(
                children: [
                  Row(
                    children: [
                      if (wide) _rail(destination),
                      Expanded(
                        child: Column(
                          children: [
                            _header(context, destination, store),
                            Expanded(child: _page(destination)),
                            _footer(context),
                            if (!wide) _bottomBar(destination),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (store.streamActive) const StreamScreen(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _rail(AppDestination destination) {
    final store = ShellScope.of(context);
    return NavigationRail(
      extended: true,
      minWidth: OpenNowTokens.railCollapsedWidth,
      groupAlignment: -0.8,
      selectedIndex: destination.navIndex,
      onDestinationSelected: store.goTo,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              color: OpenNowColors.of(context).focus,
            ),
            const SizedBox(width: 10),
            Text(
              'OPENNOW',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.9),
            ),
          ],
        ),
      ),
      destinations: [
        for (final item in AppDestination.values)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
      trailing: Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _profileTile(store.account),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(AppDestination destination) {
    final store = ShellScope.of(context);
    return BottomNavigationBar(
      currentIndex: destination.navIndex,
      onTap: store.goTo,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: OpenNowColors.of(context).focus,
      items: [
        for (final item in AppDestination.values)
          BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
      ],
    );
  }

  Widget _header(
    BuildContext context,
    AppDestination destination,
    ShellStore store,
  ) {
    final colors = OpenNowColors.of(context);
    return Container(
      height: OpenNowTokens.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.shell.withValues(alpha: 0.66),
        border: Border(bottom: BorderSide(color: colors.seam)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  destination.label.toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  store.demoMode
                      ? 'DEMO MODE · CORE UNAVAILABLE'
                      : 'GEFORCE NOW',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search your library / the store / friends',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: colors.raised,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final colors = OpenNowColors.of(context);
    return Container(
      height: OpenNowTokens.statusBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.shell.withValues(alpha: 0.78),
        border: Border(top: BorderSide(color: colors.seam)),
      ),
      child: Row(
        children: [
          Text(
            '↑↓ / Enter   ·   Ctrl K   ·   ?',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Spacer(),
          const UpdateChip(),
          const SizedBox(width: 16),
          Text('AUTO · 24 ms', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.mint,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTile(Account? account) {
    final colors = OpenNowColors.of(context);
    return Container(
      height: OpenNowTokens.rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.focus,
            child: Text(
              (account?.displayName ?? '?').substring(0, 1).toUpperCase(),
              style: TextStyle(color: colors.focusText, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  account?.displayName ?? 'Not signed in',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  account?.membershipTier.name.toUpperCase() ?? '—',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more, size: 16),
        ],
      ),
    );
  }

  Widget _page(AppDestination destination) {
    final query = _search.text.trim().toLowerCase();
    return switch (destination) {
      AppDestination.home => HomeScreen(query: query),
      AppDestination.library => LibraryScreen(query: query),
      AppDestination.store => StoreScreen(query: query),
      AppDestination.friends => const FriendsScreen(),
      AppDestination.updates => const UpdatesScreen(),
      AppDestination.settings => const SettingsScreen(),
    };
  }
}

/// Footer update status; mirrors DesktopUpdateChip.qml states.
class UpdateChip extends StatelessWidget {
  const UpdateChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = OpenNowColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('UP TO DATE', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
