import 'package:aves/widgets/aves_app.dart';
import 'package:aves/theme/m3e_tokens.dart';
import 'package:aves_utils/aves_utils.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class Themes {
  static const _titleTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: .normal,
    fontFeatures: [FontFeature.enable('smcp')],
  );

  static String asButtonLabel(String s) => s.toUpperCase();

  static TextStyle searchFieldStyle(BuildContext context) => Theme.of(context).textTheme.bodyLarge!;

  static Color overlayBackgroundColor({
    required Brightness brightness,
    required bool blurred,
  }) {
    switch (brightness) {
      case .dark:
        return blurred ? Colors.black26 : Colors.black45;
      case .light:
        return blurred ? Colors.white54 : const Color(0xCCFFFFFF);
    }
  }

  static bool _isDarkTheme(ColorScheme colors) => colors.brightness == Brightness.dark && colors.surface != Colors.black;

  static Color firstLayerColor(BuildContext context) => _schemeFirstLayer(Theme.of(context).colorScheme);

  static Color _schemeFirstLayer(ColorScheme colors) => _isDarkTheme(colors) ? colors.surfaceContainer : colors.surface;

  static Color _schemeCardLayer(ColorScheme colors) => _isDarkTheme(colors) ? _schemeSecondLayer(colors) : colors.surfaceContainerLow;

  static Color secondLayerColor(BuildContext context) => _schemeSecondLayer(Theme.of(context).colorScheme);

  static Color _schemeSecondLayer(ColorScheme colors) => _isDarkTheme(colors) ? colors.surfaceContainerHigh : colors.surfaceContainer;

  static Color thirdLayerColor(BuildContext context) => _schemeThirdLayer(Theme.of(context).colorScheme);

  static Color _schemeThirdLayer(ColorScheme colors) => _isDarkTheme(colors) ? colors.surfaceContainerHighest : colors.surfaceContainerHigh;

  static Color _unselectedWidgetColor(ColorScheme colors) => colors.onSurface.withValues(alpha: .6);

  static Color backgroundTextColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Color.alphaBlend(colors.surfaceTint, colors.onSurface).withValues(alpha: .5);
  }

  static final _typography = Typography.material2021(platform: TargetPlatform.android);

  /// Material 3 Expressive typography — tighter tracking on large text,
  /// slightly heavier weight on titles. Applied on top of the base 2021 set.
  static TextTheme _emphasized(TextTheme base) {
    TextStyle title(TextStyle? s, {double tracking = -0.4, FontWeight weight = FontWeight.w600}) {
      if (s == null) return const TextStyle();
      return s.copyWith(fontWeight: weight, letterSpacing: tracking);
    }

    return base.copyWith(
      headlineLarge: title(base.headlineLarge, tracking: -1.0, weight: FontWeight.w500),
      headlineMedium: title(base.headlineMedium, tracking: -0.75, weight: FontWeight.w500),
      headlineSmall: title(base.headlineSmall, tracking: -0.5, weight: FontWeight.w500),
      titleLarge: title(base.titleLarge),
      titleMedium: title(base.titleMedium, tracking: -0.2),
      titleSmall: title(base.titleSmall, tracking: -0.1),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData _baseTheme(ColorScheme colors, bool deviceInitialized) {
    return ThemeData(
      // M3E TOKENS
      extensions: [M3ETokens.fromColorScheme(colors)],
      // COLOR
      brightness: colors.brightness,
      canvasColor: _schemeSecondLayer(colors),
      cardColor: _schemeCardLayer(colors),
      colorScheme: colors,
      dividerColor: colors.outlineVariant,
      scaffoldBackgroundColor: _schemeFirstLayer(colors),
      // TYPOGRAPHY & ICONOGRAPHY
      iconTheme: _iconTheme(colors),
      typography: _typography,
      // COMPONENT THEMES
      navigationBarTheme: _navigationBarTheme(colors),
      checkboxTheme: _checkboxTheme(colors),
      drawerTheme: _drawerTheme(colors),
      floatingActionButtonTheme: _floatingActionButtonTheme(colors),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _schemeFirstLayer(colors),
        // M3E: pill-shaped indicator behind selected destination
        indicatorColor: colors.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        useIndicator: true,
        selectedIconTheme: IconThemeData(color: colors.onSecondaryContainer, size: 26),
        unselectedIconTheme: IconThemeData(color: _unselectedWidgetColor(colors), size: 24),
        selectedLabelTextStyle: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: _unselectedWidgetColor(colors), fontWeight: FontWeight.w500),
      ),
      radioTheme: _radioTheme(colors),
      sliderTheme: _sliderTheme(colors),
      tabBarTheme: TabBarThemeData(
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0),
      ),
      tooltipTheme: _tooltipTheme,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        circularTrackColor: colors.surfaceContainerHighest,
        linearTrackColor: colors.surfaceContainerHighest,
        linearMinHeight: 6,
        refreshBackgroundColor: colors.surfaceContainerHigh,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _schemeSecondLayer(colors),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBackgroundColor: _schemeSecondLayer(colors),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: colors.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _schemeSecondLayer(colors),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      // M3E additions
      cardTheme: CardThemeData(
        color: _schemeCardLayer(colors),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        elevation: 0,
        pressElevation: 0,
        backgroundColor: _schemeSecondLayer(colors),
        selectedColor: colors.secondaryContainer,
        labelStyle: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(ColorScheme colors) {
    final iconTheme = _iconTheme(colors);
    return NavigationBarThemeData(
      elevation: 0,
      backgroundColor: _schemeFirstLayer(colors),
      indicatorColor: colors.secondaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return iconTheme.copyWith(color: colors.onSecondaryContainer);
        }
        return iconTheme.copyWith(color: _unselectedWidgetColor(colors));
      }),
      height: 72,
    );
  }

  static CheckboxThemeData _checkboxTheme(ColorScheme colors) => CheckboxThemeData(
    side: BorderSide(width: 2.0, color: _unselectedWidgetColor(colors)),
  );

  static DrawerThemeData _drawerTheme(ColorScheme colors) => DrawerThemeData(
    backgroundColor: _schemeSecondLayer(colors),
  );

  static IconThemeData _iconTheme(ColorScheme colors) => IconThemeData(
    // increased weight (from default 400 to 600)
    // applied to variable fonts from `material_symbols_icons`,
    // to match the fixed-weight icons from `flutter_material_design_icons`
    weight: 600,
    grade: 0,
    opticalSize: 48,
    color: colors.onSurface,
  );

  static const _listTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  );

  static PopupMenuThemeData _popupMenuTheme(ColorScheme colors, TextTheme textTheme) {
    return PopupMenuThemeData(
      color: _schemeSecondLayer(colors),
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        // adapted from M3 defaults
        final TextStyle style = textTheme.labelLarge!;
        if (states.contains(WidgetState.disabled)) {
          return style.apply(color: colors.onSurface.withValues(alpha: .38));
        }
        return style.apply(color: colors.onSurface);
      }),
      iconColor: colors.onSurface,
    );
  }

  static FloatingActionButtonThemeData _floatingActionButtonTheme(ColorScheme colors) {
    return FloatingActionButtonThemeData(
      foregroundColor: colors.onPrimary,
      backgroundColor: colors.primary,
    );
  }

  // adapted from M3 defaults
  static RadioThemeData _radioTheme(ColorScheme colors) => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: .38);
        }
        return colors.primary;
      }
      if (states.contains(WidgetState.disabled)) {
        return colors.onSurface.withValues(alpha: .38);
      }
      if (states.contains(WidgetState.pressed)) {
        return colors.onSurface;
      }
      if (states.contains(WidgetState.hovered)) {
        return colors.onSurface;
      }
      if (states.contains(WidgetState.focused)) {
        return colors.onSurface;
      }
      return _unselectedWidgetColor(colors);
    }),
  );

  static SliderThemeData _sliderTheme(ColorScheme colors) => SliderThemeData(
    inactiveTrackColor: colors.primary.withValues(alpha: .24),
  );

  static SnackBarThemeData _snackBarTheme(ColorScheme colors) => SnackBarThemeData(
    actionTextColor: colors.primary,
    behavior: SnackBarBehavior.floating,
    backgroundColor: _schemeSecondLayer(colors),
    contentTextStyle: TextStyle(color: colors.onSurface),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 3,
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static const _tooltipTheme = TooltipThemeData(
    verticalOffset: 32,
  );

  // light

  static final _lightThemeTypo = _typography.black;
  static final _lightTitleColor = _lightThemeTypo.titleMedium!.color!;
  static final _lightLabelColor = _lightThemeTypo.labelMedium!.color!;
  static const _lightActionIconColor = Color(0xAA000000);
  static const _lightOnSurface = Colors.black;

  static ThemeData lightTheme(Color accentColor, bool deviceInitialized) {
    final onAccent = ColorUtils.textColorOn(accentColor);
    final colors = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
      primary: accentColor,
      onPrimary: onAccent,
      secondary: accentColor,
      onSecondary: onAccent,
      onSurface: _lightOnSurface,
    );
    final textTheme = _emphasized(_lightThemeTypo);
    return _baseTheme(colors, deviceInitialized).copyWith(
      // TYPOGRAPHY & ICONOGRAPHY
      textTheme: textTheme,
      // COMPONENT THEMES
      appBarTheme: AppBarTheme(
        backgroundColor: _schemeFirstLayer(colors),
        // `foregroundColor` is used by icons
        foregroundColor: _lightActionIconColor,
        // `titleTextStyle.color` is used by text
        titleTextStyle: _titleTextStyle.copyWith(color: _lightTitleColor),
        // `systemOverlayStyle` is assumed by the app to never be null
        systemOverlayStyle: deviceInitialized ? AvesApp.systemUIStyleForBrightness(colors.brightness, _schemeFirstLayer(colors)) : const SystemUiOverlayStyle(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _schemeSecondLayer(colors),
        titleTextStyle: _titleTextStyle.copyWith(color: _lightTitleColor),
      ),
      listTileTheme: _listTileTheme.copyWith(
        iconColor: _lightActionIconColor,
      ),
      popupMenuTheme: _popupMenuTheme(colors, textTheme),
      snackBarTheme: _snackBarTheme(colors),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightLabelColor,
        ),
      ),
    );
  }

  // dark

  static final _darkThemeTypo = _typography.white;
  static final _darkTitleColor = _darkThemeTypo.titleMedium!.color!;
  static final _darkBodyColor = _darkThemeTypo.bodyMedium!.color!;
  static final _darkLabelColor = _darkThemeTypo.labelMedium!.color!;
  static const _darkOnSurface = Colors.white;

  static ColorScheme _darkColorScheme(Color accentColor) {
    final onAccent = ColorUtils.textColorOn(accentColor);
    final colors = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      primary: accentColor,
      onPrimary: onAccent,
      secondary: accentColor,
      onSecondary: onAccent,
      onSurface: _darkOnSurface,
    );
    return colors;
  }

  static ThemeData _baseDarkTheme(ColorScheme colors, bool deviceInitialized) {
    final textTheme = _emphasized(_darkThemeTypo);
    return _baseTheme(colors, deviceInitialized).copyWith(
      // TYPOGRAPHY & ICONOGRAPHY
      textTheme: textTheme,
      // COMPONENT THEMES
      appBarTheme: AppBarTheme(
        backgroundColor: _schemeFirstLayer(colors),
        // `foregroundColor` is used by icons
        foregroundColor: _darkTitleColor,
        // `titleTextStyle.color` is used by text
        titleTextStyle: _titleTextStyle.copyWith(color: _darkTitleColor),
        // `systemOverlayStyle` is assumed by the app to never be null
        systemOverlayStyle: deviceInitialized ? AvesApp.systemUIStyleForBrightness(colors.brightness, _schemeFirstLayer(colors)) : const SystemUiOverlayStyle(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _schemeSecondLayer(colors),
        titleTextStyle: _titleTextStyle.copyWith(color: _darkTitleColor),
      ),
      listTileTheme: _listTileTheme,
      popupMenuTheme: _popupMenuTheme(colors, textTheme),
      snackBarTheme: _snackBarTheme(colors).copyWith(
        backgroundColor: _schemeSecondLayer(colors),
        contentTextStyle: TextStyle(
          color: _darkBodyColor,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkLabelColor,
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor, bool deviceInitialized) {
    final colors = _darkColorScheme(accentColor);
    return _baseDarkTheme(colors, deviceInitialized);
  }

  // black

  static ThemeData blackTheme(Color accentColor, bool deviceInitialized) {
    final colors = _darkColorScheme(accentColor).copyWith(
      surface: Colors.black,
    );
    return _baseDarkTheme(colors, deviceInitialized);
  }
}
