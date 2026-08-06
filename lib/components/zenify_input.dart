import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ZenifyInput extends StatefulWidget {
  final TextEditingController? controller;
  final Widget? placeholder;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? suffix;

  const ZenifyInput({
    super.key,
    this.controller,
    this.placeholder,
    this.obscureText = false,
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.suffix,
  });

  @override
  State<ZenifyInput> createState() => _ZenifyInputState();
}

class _ZenifyInputState extends State<ZenifyInput> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? colorScheme.background : colorScheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? colorScheme.primary : colorScheme.border,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ShadInput(
              focusNode: _focusNode,
              controller: widget.controller,
              placeholder: widget.placeholder,
              obscureText: widget.obscureText,
              onChanged: widget.onChanged,
              autofocus: widget.autofocus,
              decoration: const ShadDecoration(
                border: ShadBorder.none,
                focusedBorder: ShadBorder.none,
                secondaryBorder: ShadBorder.none,
                secondaryFocusedBorder: ShadBorder.none,
              ),
            ),
          ),
          if (widget.suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: widget.suffix!,
            ),
        ],
      ),
    );
  }
}
