import 'package:flutter/material.dart';

/// The desktop screen is an explicit placeholder; the real Friends UI lives in
/// the console overlay (`FriendsOverlay`). Keep that distinction in the port.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.people_outline,
          size: 48,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text('Coming soon', style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}
