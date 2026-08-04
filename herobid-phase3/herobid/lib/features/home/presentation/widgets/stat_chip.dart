import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.large = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    final iconSize = large ? 28.0 : 20.0;
    final valueStyle = large
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)
        : Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 20 : 14,
        vertical: large ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: iconSize),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}
