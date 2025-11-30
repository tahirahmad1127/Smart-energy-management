import 'package:flutter/material.dart';
import 'package:news_app/theme/energy_theme.dart';

class EnergyGlowCard extends StatelessWidget {
  const EnergyGlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 10),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: gradient ??
            LinearGradient(
              colors: [
                EnergyTheme.panel,
                EnergyTheme.panel.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        border: Border.all(
          color: EnergyTheme.electricBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: EnergyTheme.electricBlue.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: child,
    );
  }
}

