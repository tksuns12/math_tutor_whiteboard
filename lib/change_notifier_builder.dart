import 'package:flutter/material.dart';

class ChangeNotifierBuilder<T extends ChangeNotifier> extends AnimatedWidget {
  ChangeNotifierBuilder({
    Key? key,
    required this.notifier,
    required this.builder,
    this.child,
  }) : super(key: key, listenable: notifier ?? ChangeNotifier());

  final T? notifier;
  final Widget Function(
    BuildContext context,
    T? notifier,
    Widget? child,
  ) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return builder(context, notifier, child);
  }
}
