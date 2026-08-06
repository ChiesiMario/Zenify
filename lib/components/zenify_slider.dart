import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ZenifySlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final ValueChanged<double>? onChangeStart;
  final String? semanticFormatterCallback;
  
  // Styling overrides (optional)
  final Color? activeColor;
  final Color? inactiveColor;
  final double trackHeight;
  final double thumbRadius;
  final bool showThumb;

  const ZenifySlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    required this.onChanged,
    this.onChangeEnd,
    this.onChangeStart,
    this.semanticFormatterCallback,
    this.activeColor,
    this.inactiveColor,
    this.trackHeight = 4.0,
    this.thumbRadius = 6.0,
    this.showThumb = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colorScheme = theme.colorScheme;
    
    final finalActiveColor = activeColor ?? colorScheme.primary;
    final finalInactiveColor = inactiveColor ?? colorScheme.border;

    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: finalActiveColor,
        inactiveTrackColor: finalInactiveColor,
        thumbColor: finalActiveColor,
        trackHeight: trackHeight,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: showThumb 
            ? RoundSliderThumbShape(enabledThumbRadius: thumbRadius)
            : const RoundSliderThumbShape(enabledThumbRadius: 0),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
