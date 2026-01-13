import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities
class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if device is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
      vertical: value(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
    );
  }

  /// Get grid cross axis count for library
  static int gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 6;
    if (width >= tabletBreakpoint) return 5;
    if (width >= mobileBreakpoint) return 4;
    if (width >= 400) return 3;
    return 2;
  }

  /// Get horizontal list item width
  static double horizontalListItemWidth(BuildContext context) {
    return value(context, mobile: 120.0, tablet: 140.0, desktop: 160.0);
  }

  /// Get card aspect ratio
  static double bookCardAspectRatio(BuildContext context) {
    return value(context, mobile: 0.65, tablet: 0.68, desktop: 0.7);
  }

  /// Get font scale factor
  static double fontScale(BuildContext context) {
    return value(context, mobile: 1.0, tablet: 1.05, desktop: 1.1);
  }

  /// Get icon size
  static double iconSize(BuildContext context, {double base = 24}) {
    return base * value(context, mobile: 1.0, tablet: 1.1, desktop: 1.2);
  }

  /// Get max content width (for centering on large screens)
  static double? maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return null;
  }

  /// Wrap content with max width constraint
  static Widget constrainWidth(BuildContext context, {required Widget child}) {
    final maxWidth = maxContentWidth(context);
    if (maxWidth == null) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(
          context,
          Responsive.isMobile(context),
          Responsive.isTablet(context),
          Responsive.isDesktop(context),
        );
      },
    );
  }
}

/// Responsive layout that shows different widgets based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (Responsive.isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}
