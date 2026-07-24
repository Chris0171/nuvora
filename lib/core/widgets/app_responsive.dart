import 'package:flutter/material.dart';

class AppResponsive {
	static const double tabletBreakpoint = 720;
	static const double desktopBreakpoint = 1100;

	static bool isTablet(BuildContext context) {
		final width = MediaQuery.sizeOf(context).width;
		return width >= tabletBreakpoint && width < desktopBreakpoint;
	}

	static bool isDesktop(BuildContext context) {
		final width = MediaQuery.sizeOf(context).width;
		return width >= desktopBreakpoint;
	}

	static double pagePadding(BuildContext context) {
		if (isDesktop(context)) return 32;
		if (isTablet(context)) return 24;
		return 16;
	}

	static double maxContentWidth(BuildContext context) {
		if (isDesktop(context)) return 1120;
		if (isTablet(context)) return 920;
		return double.infinity;
	}

	static int adaptiveColumns(
		BuildContext context, {
		int mobile = 1,
		int tablet = 2,
		int desktop = 3,
	}) {
		if (isDesktop(context)) return desktop;
		if (isTablet(context)) return tablet;
		return mobile;
	}

	static double titleScale(BuildContext context) {
		if (isDesktop(context)) return 1.12;
		if (isTablet(context)) return 1.06;
		return 1.0;
	}
}