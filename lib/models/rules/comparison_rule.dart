import '../card_side.dart';

class ComparisonRule {
  final bool requireNumberGreater; // attacker.number > defender.number
  final bool allowEqual;           // attacker.number >= defender.number
  final bool requireShapeMatch;
  final bool requireColorMatch;    // shapeColor must match
  final bool requireBothShapeAndColor;

  const ComparisonRule({
    this.requireNumberGreater = true,
    this.allowEqual = false,
    this.requireShapeMatch = false,
    this.requireColorMatch = false,
    this.requireBothShapeAndColor = false,
  });

  bool attackSucceeds(CardSide attacker, CardSide defender) {
    // Number check
    if (requireNumberGreater || allowEqual) {
      final numOk = allowEqual
          ? attacker.number >= defender.number
          : attacker.number > defender.number;
      if (!numOk) return false;
    }

    // Shape match
    if (requireShapeMatch && attacker.shape != defender.shape) return false;

    // Color match
    if (requireColorMatch && attacker.shapeColor != defender.shapeColor) return false;

    // Both shape and color
    if (requireBothShapeAndColor) {
      if (attacker.shape != defender.shape) return false;
      if (attacker.shapeColor != defender.shapeColor) return false;
    }

    return true;
  }

  factory ComparisonRule.fromJson(Map<String, dynamic> json) => ComparisonRule(
        requireNumberGreater:
            json['requireNumberGreater'] as bool? ?? true,
        allowEqual: json['allowEqual'] as bool? ?? false,
        requireShapeMatch: json['requireShapeMatch'] as bool? ?? false,
        requireColorMatch: json['requireColorMatch'] as bool? ?? false,
        requireBothShapeAndColor:
            json['requireBothShapeAndColor'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'requireNumberGreater': requireNumberGreater,
        'allowEqual': allowEqual,
        'requireShapeMatch': requireShapeMatch,
        'requireColorMatch': requireColorMatch,
        'requireBothShapeAndColor': requireBothShapeAndColor,
      };

  ComparisonRule copyWith({
    bool? requireNumberGreater,
    bool? allowEqual,
    bool? requireShapeMatch,
    bool? requireColorMatch,
    bool? requireBothShapeAndColor,
  }) =>
      ComparisonRule(
        requireNumberGreater: requireNumberGreater ?? this.requireNumberGreater,
        allowEqual: allowEqual ?? this.allowEqual,
        requireShapeMatch: requireShapeMatch ?? this.requireShapeMatch,
        requireColorMatch: requireColorMatch ?? this.requireColorMatch,
        requireBothShapeAndColor:
            requireBothShapeAndColor ?? this.requireBothShapeAndColor,
      );
}
