import 'package:material_ui/material_ui.dart';

/// Material 3 Expressive design tokens, carried as a [ThemeExtension].
///
/// Phase 1 — no consumers yet. Phase 2 will read shape/motion tokens for
/// spring motion, Phase 3 will read them for expressive component variants.
///
/// Shape scale follows the M3 shape library: fixed radii for the 5 standard
/// sizes, plus the expressive shape families (pill, cookie, sunny, clover)
/// represented here as a normalized [double] progress parameter that the
/// consumer maps through a shape polygon if it needs to.
class M3ETokens extends ThemeExtension<M3ETokens> {
  // shape scale
  final double shapeExtraSmall;
  final double shapeSmall;
  final double shapeMedium;
  final double shapeLarge;
  final double shapeExtraLarge;
  final double shapeExtraExtraLarge;

  // expressive shape family parameter (0 = rounded square, 1 = fully polygonal)
  final double shapeFamilyProgress;

  // motion — durations
  final Duration durationShort1;
  final Duration durationShort2;
  final Duration durationShort3;
  final Duration durationShort4;
  final Duration durationMedium1;
  final Duration durationMedium2;
  final Duration durationMedium3;
  final Duration durationMedium4;
  final Duration durationLong1;
  final Duration durationLong2;
  final Duration durationLong3;
  final Duration durationLong4;

  // motion — spring descriptors (damping ratio, stiffness, mass)
  final double springDamping;
  final double springStiffness;
  final double springMass;

  // emphasized typography axes
  final double emphasizedWeightDelta;
  final double emphasizedLetterSpacing;

  const M3ETokens({
    this.shapeExtraSmall = 4.0,
    this.shapeSmall = 8.0,
    this.shapeMedium = 12.0,
    this.shapeLarge = 16.0,
    this.shapeExtraLarge = 28.0,
    this.shapeExtraExtraLarge = 48.0,
    this.shapeFamilyProgress = 0.0,
    this.durationShort1 = const Duration(milliseconds: 50),
    this.durationShort2 = const Duration(milliseconds: 100),
    this.durationShort3 = const Duration(milliseconds: 150),
    this.durationShort4 = const Duration(milliseconds: 200),
    this.durationMedium1 = const Duration(milliseconds: 250),
    this.durationMedium2 = const Duration(milliseconds: 300),
    this.durationMedium3 = const Duration(milliseconds: 350),
    this.durationMedium4 = const Duration(milliseconds: 400),
    this.durationLong1 = const Duration(milliseconds: 450),
    this.durationLong2 = const Duration(milliseconds: 500),
    this.durationLong3 = const Duration(milliseconds: 550),
    this.durationLong4 = const Duration(milliseconds: 600),
    this.springDamping = 0.85,
    this.springStiffness = 380.0,
    this.springMass = 1.0,
    this.emphasizedWeightDelta = 100.0,
    this.emphasizedLetterSpacing = 0.1,
  });

  /// Convenience constructor returning the standard Material 3 Expressive
  /// defaults. Signature takes a [ColorScheme] so future variants can key
  /// off brightness, but nothing is derived from it yet.
  factory M3ETokens.fromColorScheme(ColorScheme colors) => const M3ETokens();

  @override
  M3ETokens copyWith({
    double? shapeExtraSmall,
    double? shapeSmall,
    double? shapeMedium,
    double? shapeLarge,
    double? shapeExtraLarge,
    double? shapeExtraExtraLarge,
    double? shapeFamilyProgress,
    Duration? durationShort1,
    Duration? durationShort2,
    Duration? durationShort3,
    Duration? durationShort4,
    Duration? durationMedium1,
    Duration? durationMedium2,
    Duration? durationMedium3,
    Duration? durationMedium4,
    Duration? durationLong1,
    Duration? durationLong2,
    Duration? durationLong3,
    Duration? durationLong4,
    double? springDamping,
    double? springStiffness,
    double? springMass,
    double? emphasizedWeightDelta,
    double? emphasizedLetterSpacing,
  }) {
    return M3ETokens(
      shapeExtraSmall: shapeExtraSmall ?? this.shapeExtraSmall,
      shapeSmall: shapeSmall ?? this.shapeSmall,
      shapeMedium: shapeMedium ?? this.shapeMedium,
      shapeLarge: shapeLarge ?? this.shapeLarge,
      shapeExtraLarge: shapeExtraLarge ?? this.shapeExtraLarge,
      shapeExtraExtraLarge: shapeExtraExtraLarge ?? this.shapeExtraExtraLarge,
      shapeFamilyProgress: shapeFamilyProgress ?? this.shapeFamilyProgress,
      durationShort1: durationShort1 ?? this.durationShort1,
      durationShort2: durationShort2 ?? this.durationShort2,
      durationShort3: durationShort3 ?? this.durationShort3,
      durationShort4: durationShort4 ?? this.durationShort4,
      durationMedium1: durationMedium1 ?? this.durationMedium1,
      durationMedium2: durationMedium2 ?? this.durationMedium2,
      durationMedium3: durationMedium3 ?? this.durationMedium3,
      durationMedium4: durationMedium4 ?? this.durationMedium4,
      durationLong1: durationLong1 ?? this.durationLong1,
      durationLong2: durationLong2 ?? this.durationLong2,
      durationLong3: durationLong3 ?? this.durationLong3,
      durationLong4: durationLong4 ?? this.durationLong4,
      springDamping: springDamping ?? this.springDamping,
      springStiffness: springStiffness ?? this.springStiffness,
      springMass: springMass ?? this.springMass,
      emphasizedWeightDelta: emphasizedWeightDelta ?? this.emphasizedWeightDelta,
      emphasizedLetterSpacing: emphasizedLetterSpacing ?? this.emphasizedLetterSpacing,
    );
  }

  @override
  M3ETokens lerp(covariant M3ETokens? other, double t) {
    if (other == null) return this;
    double l(double a, double b) => a + (b - a) * t;
    Duration ld(Duration a, Duration b) => Duration(
          microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t).round(),
        );
    return M3ETokens(
      shapeExtraSmall: l(shapeExtraSmall, other.shapeExtraSmall),
      shapeSmall: l(shapeSmall, other.shapeSmall),
      shapeMedium: l(shapeMedium, other.shapeMedium),
      shapeLarge: l(shapeLarge, other.shapeLarge),
      shapeExtraLarge: l(shapeExtraLarge, other.shapeExtraLarge),
      shapeExtraExtraLarge: l(shapeExtraExtraLarge, other.shapeExtraExtraLarge),
      shapeFamilyProgress: l(shapeFamilyProgress, other.shapeFamilyProgress),
      durationShort1: ld(durationShort1, other.durationShort1),
      durationShort2: ld(durationShort2, other.durationShort2),
      durationShort3: ld(durationShort3, other.durationShort3),
      durationShort4: ld(durationShort4, other.durationShort4),
      durationMedium1: ld(durationMedium1, other.durationMedium1),
      durationMedium2: ld(durationMedium2, other.durationMedium2),
      durationMedium3: ld(durationMedium3, other.durationMedium3),
      durationMedium4: ld(durationMedium4, other.durationMedium4),
      durationLong1: ld(durationLong1, other.durationLong1),
      durationLong2: ld(durationLong2, other.durationLong2),
      durationLong3: ld(durationLong3, other.durationLong3),
      durationLong4: ld(durationLong4, other.durationLong4),
      springDamping: l(springDamping, other.springDamping),
      springStiffness: l(springStiffness, other.springStiffness),
      springMass: l(springMass, other.springMass),
      emphasizedWeightDelta: l(emphasizedWeightDelta, other.emphasizedWeightDelta),
      emphasizedLetterSpacing: l(emphasizedLetterSpacing, other.emphasizedLetterSpacing),
    );
  }
}

/// Convenience accessor — `context.m3e` returns the ambient tokens, falling
/// back to defaults if the extension is missing (e.g. in tests, in a widget
/// rendered above the `MaterialApp`).
extension M3ETokensX on BuildContext {
  M3ETokens get m3e => Theme.of(this).extension<M3ETokens>() ?? const M3ETokens();
}
