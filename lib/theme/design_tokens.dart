import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, typography, and styling throughout the app
class DesignTokens {
  // Spacing system based on 8px grid
  static const EdgeInsets spaceNone = EdgeInsets.zero;
  static const EdgeInsets spaceXS = EdgeInsets.all(4);
  static const EdgeInsets spaceS = EdgeInsets.all(8);
  static const EdgeInsets spaceM = EdgeInsets.all(16);
  static const EdgeInsets spaceL = EdgeInsets.all(24);
  static const EdgeInsets spaceXL = EdgeInsets.all(32);
  static const EdgeInsets spaceXXL = EdgeInsets.all(48);

  // Horizontal spacing
  static const EdgeInsets spaceHorizontalXS = EdgeInsets.symmetric(
    horizontal: 4,
  );
  static const EdgeInsets spaceHorizontalS = EdgeInsets.symmetric(
    horizontal: 8,
  );
  static const EdgeInsets spaceHorizontalM = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const EdgeInsets spaceHorizontalL = EdgeInsets.symmetric(
    horizontal: 24,
  );
  static const EdgeInsets spaceHorizontalXL = EdgeInsets.symmetric(
    horizontal: 32,
  );

  // Vertical spacing
  static const EdgeInsets spaceVerticalXS = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets spaceVerticalS = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets spaceVerticalM = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets spaceVerticalL = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets spaceVerticalXL = EdgeInsets.symmetric(vertical: 32);

  // Page margins
  static const EdgeInsets pageMargin = EdgeInsets.all(16);
  static const EdgeInsets pageMarginLarge = EdgeInsets.all(24);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20);

  // Border radius
  static const double radiusNone = 0.0;
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 999.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationS = 1.0;
  static const double elevationM = 2.0;
  static const double elevationL = 4.0;
  static const double elevationXL = 8.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);
  static const Duration animationSlower = Duration(milliseconds: 500);

  // Animation curves
  static const Curve animationCurveStandard = Curves.easeInOut;
  static const Curve animationCurveDecelerate = Curves.easeOut;
  static const Curve animationCurveAccelerate = Curves.easeIn;
  static const Curve animationCurveEmphasized = Curves.easeInOutCubic;

  // Touch targets (accessibility)
  static const double touchTargetMinSize = 44.0;
  static const double touchTargetComfortableSize = 48.0;

  // Icon sizes
  static const double iconSizeXS = 12.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;
  static const double iconSizeXXL = 48.0;

  // Common layout constraints
  static const double maxContentWidth = 600.0;
  static const double minTouchTarget = 44.0;

  // Typography spacing
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightLoose = 1.6;

  // Letter spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingLoose = 0.5;
  static const double letterSpacingWide = 1.0;
}

/// Extension to provide semantic access to spacing values
extension DesignTokensSpacing on EdgeInsets {
  static const EdgeInsets pageContent = DesignTokens.spaceHorizontalM;
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets cardContent = EdgeInsets.all(16);
  static const EdgeInsets buttonContent = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );
}

/// Extension for semantic border radius access
extension DesignTokensRadius on BorderRadius {
  static BorderRadius get small => BorderRadius.circular(DesignTokens.radiusS);
  static BorderRadius get medium => BorderRadius.circular(DesignTokens.radiusM);
  static BorderRadius get large => BorderRadius.circular(DesignTokens.radiusL);
  static BorderRadius get extraLarge =>
      BorderRadius.circular(DesignTokens.radiusXL);
}
