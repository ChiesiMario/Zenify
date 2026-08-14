import 'package:flutter/material.dart';

class ZenifyScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const ZenifyScrollbar({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      interactive: true,
      child: child,
    );
  }
}

class ZenifyScrollBehavior extends MaterialScrollBehavior {
  const ZenifyScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
        return child;
      case Axis.vertical:
        return Scrollbar(
          controller: details.controller,
          interactive: true,
          child: child,
        );
    }
  }
}

