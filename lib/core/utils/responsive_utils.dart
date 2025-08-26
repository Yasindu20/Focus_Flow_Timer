import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoint constants
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Screen size helpers
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
      
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
      
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
      
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;
      
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.height < 700;
  
  // Responsive spacing
  static double getHorizontalPadding(BuildContext context) {
    if (isSmallMobile(context)) return 12;
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 24;
    return 32;
  }
  
  static double getVerticalPadding(BuildContext context) {
    if (isSmallScreen(context)) return 8;
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }
  
  // Responsive font sizes
  static double getHeadlineSize(BuildContext context) {
    if (isSmallMobile(context)) return 20;
    if (isMobile(context)) return 24;
    if (isTablet(context)) return 28;
    return 32;
  }
  
  static double getBodySize(BuildContext context) {
    if (isSmallMobile(context)) return 13;
    if (isMobile(context)) return 14;
    if (isTablet(context)) return 15;
    return 16;
  }
  
  static double getCaptionSize(BuildContext context) {
    if (isSmallMobile(context)) return 11;
    if (isMobile(context)) return 12;
    return 13;
  }
  
  // Grid configurations
  static int getGridCrossAxisCount(BuildContext context, {
    int mobileCount = 2,
    int tabletCount = 3,
    int desktopCount = 4,
  }) {
    if (isSmallMobile(context)) return mobileCount - 1;
    if (isMobile(context)) return mobileCount;
    if (isTablet(context)) return tabletCount;
    return desktopCount;
  }
  
  static double getGridSpacing(BuildContext context) {
    if (isSmallMobile(context)) return 6;
    if (isMobile(context)) return 8;
    if (isTablet(context)) return 12;
    return 16;
  }
  
  // Safe constraints for containers
  static BoxConstraints getSafeConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BoxConstraints(
      maxWidth: size.width * 0.95,
      maxHeight: size.height * 0.9,
    );
  }
  
  // Safe text overflow handling
  static int getMaxLines(BuildContext context, {int? override}) {
    if (override != null) return override;
    return isSmallMobile(context) ? 1 : 2;
  }
}

/// A responsive text widget that automatically handles overflow and scaling
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;
  final double? scaleFactor;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxLines = ResponsiveUtils.getMaxLines(context, override: maxLines);
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.center ? Alignment.center : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Text(
          text,
          style: style?.copyWith(
            fontSize: scaleFactor != null 
                ? (style?.fontSize ?? 14) * scaleFactor! 
                : style?.fontSize,
          ),
          maxLines: effectiveMaxLines,
          overflow: overflow,
          textAlign: textAlign,
        ),
      ),
    );
  }
}

/// A responsive container that adjusts padding based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: ResponsiveUtils.getSafeConstraints(context),
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveUtils.getVerticalPadding(context),
      ),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}