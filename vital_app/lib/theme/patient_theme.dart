import 'package:flutter/material.dart';

/// Shared theme constants for patient screens
class PatientTheme {
  // Professional wellness color palette
  static const Color primaryColor = Color(0xFF4CAF50); // Green
  static const Color accentColor = Color(0xFF81C784); // Light Green
  static const Color secondaryColor = Color(0xFF2196F3); // Blue
  static const Color tertiaryColor = Color(0xFF64B5F6); // Light Blue
  static const Color surfaceColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;

  // Border radius constants
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusXLarge = 24.0;

  // Spacing constants
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Card elevation
  static const double cardElevation = 0.0; // Using borders instead

  /// Build a modern card with consistent styling
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? backgroundColor,
    List<Color>? gradientColors,
    VoidCallback? onTap,
  }) {
    final decoration = BoxDecoration(
      color: backgroundColor ?? cardColor,
      borderRadius: BorderRadius.circular(borderRadius ?? borderRadiusMedium),
      border: Border.all(color: Colors.grey[200]!, width: 1),
      gradient: gradientColors != null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            )
          : null,
    );

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return Card(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? borderRadiusMedium,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? borderRadiusMedium,
          ),
          child: cardContent,
        ),
      );
    }

    return Card(
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? borderRadiusMedium),
      ),
      child: cardContent,
    );
  }

  /// Build a modern stat/metric card
  static Widget buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return buildCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Build a modern action button
  static Widget buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
    String? description,
  }) {
    return buildCard(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: enabled ? null : Colors.grey[100],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled
                    ? color.withValues(alpha: 0.15)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: enabled ? color : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: enabled ? Colors.grey[600] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a modern app bar with gradient
  static PreferredSizeWidget buildAppBar({
    required String title,
    List<Widget>? actions,
    Color? backgroundColor,
    bool centerTitle = false,
  }) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
    );
  }

  /// Build a gradient header
  static Widget buildGradientHeader({
    required Widget child,
    List<Color>? colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? [primaryColor, accentColor],
        ),
      ),
      child: child,
    );
  }
}
