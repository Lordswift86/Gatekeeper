import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility helper utilities for the GateKeeper app
class AccessibilityHelper {
  /// Wrap a widget with semantics label for screen readers
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    bool button = false,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }
  
  /// Get high contrast text style
  static TextStyle highContrastText(BuildContext context, {double fontSize = 16}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );
  }
  
  /// Check if large text is enabled
  static bool isLargeTextEnabled(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0) > 1.2;
  }
  
  /// Get minimum touch target size (48x48 per accessibility guidelines)
  static double get minTouchTarget => 48.0;
  
  /// Announce a message for screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}

/// Minimum touch target widget wrapper
class MinTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  
  const MinTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
