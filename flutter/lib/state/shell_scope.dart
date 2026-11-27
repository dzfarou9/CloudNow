import 'package:flutter/widgets.dart';

import 'shell_store.dart';

/// Makes the single shell store available to the widget tree without adding a
/// state-management dependency that would need its own code generation step.
class ShellScope extends InheritedNotifier<ShellStore> {
  const ShellScope({super.key, required ShellStore store, required super.child})
    : super(notifier: store);

  static ShellStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellScope>();
    assert(scope?.notifier != null, 'ShellScope missing above this widget');
    return scope!.notifier!;
  }
}
