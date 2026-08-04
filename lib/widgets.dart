import 'package:flutter/material.dart';

import 'level.dart' show kSolveThreshold;

/// Shared HUD parts. Extracted when the Workshop needed the same meters, ghost
/// buttons and dial as the play screen — cross-file privacy makes the choice
/// "promote or duplicate", and forty lines of duplicated chrome drift apart
/// the first time one of them is restyled.
class Meter extends StatelessWidget {
  const Meter({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final hit = value >= kSolveThreshold;
    // Rescale so the visible travel lives where the puzzle actually is.
    final t = ((value - 0.35) / (1 - 0.35)).clamp(0.0, 1.0);
    return SizedBox(
      width: 74,
      height: 3,
      child: Stack(
        children: [
          Container(color: Colors.white.withValues(alpha: 0.08)),
          FractionallySizedBox(
            widthFactor: t,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              color: hit
                  ? const Color(0xFFE0A82E)
                  : Colors.white.withValues(alpha: 0.32),
            ),
          ),
        ],
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        color: Colors.white38,
        disabledColor: Colors.white10,
        splashRadius: 20,
      );
}

class AxisDial extends StatelessWidget {
  const AxisDial(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.onStart,
      this.min = -1.6,
      this.max = 1.6});
  final double value;
  final double min, max;
  final ValueChanged<double> onChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 46),
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            activeTrackColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            thumbColor: const Color(0xFFE0A82E),
            overlayColor: const Color(0x22E0A82E),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            // Marked on grab, not per tick — the whole slide is one decision.
            onChangeStart: (_) => onStart(),
            onChanged: onChanged,
          ),
        ),
      );
}
