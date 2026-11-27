import 'package:flutter/material.dart';

import '../state/shell_scope.dart';
import '../theme/opennow_theme.dart';

/// Port of `DesktopSignInScreen.qml`: provider selection plus device-login
/// placeholder. Live device login needs `auth.device.start` from the core and
/// is therefore gated behind the demo bridge until the core is a library.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = OpenNowColors.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.shell, colors.focus.withValues(alpha: 0.25)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SIGN IN',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a provider to continue to GeForce NOW.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _showDeviceLogin(context),
                      icon: const Icon(Icons.login),
                      label: const Text('NVIDIA'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showDeviceLogin(context),
                      icon: const Icon(Icons.link),
                      label: const Text('Sign in with a partner'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeviceLogin(BuildContext context) {
    final store = ShellScope.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device login'),
        content: Text(
          store.demoMode
              ? 'The core bridge is unavailable in this build. Sign-in requires the opennow-core library (see README).'
              : 'Open GeForce NOW on another device and enter the code shown there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
