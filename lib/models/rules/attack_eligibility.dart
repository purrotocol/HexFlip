import 'dart:ui';
import '../card_side.dart';

enum AttackMode { allSides, specificShape, specificColor, shapeAndColor }

class AttackEligibilityRule {
  final AttackMode mode;
  final SymbolShape? requiredShape;
  final Color? requiredColor;

  const AttackEligibilityRule({
    this.mode = AttackMode.allSides,
    this.requiredShape,
    this.requiredColor,
  });

  bool sideCanAttack(CardSide side) {
    switch (mode) {
      case AttackMode.allSides:
        return true;
      case AttackMode.specificShape:
        return requiredShape == null || side.shape == requiredShape;
      case AttackMode.specificColor:
        return requiredColor == null || side.shapeColor == requiredColor;
      case AttackMode.shapeAndColor:
        final shapeOk = requiredShape == null || side.shape == requiredShape;
        final colorOk = requiredColor == null || side.shapeColor == requiredColor;
        return shapeOk && colorOk;
    }
  }

  factory AttackEligibilityRule.fromJson(Map<String, dynamic> json) {
    Color? color;
    if (json['requiredColor'] != null) {
      final h = (json['requiredColor'] as String).replaceFirst('#', '');
      color = Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
    }
    return AttackEligibilityRule(
      mode: AttackMode.values.byName(json['mode'] as String? ?? 'allSides'),
      requiredShape: json['requiredShape'] != null
          ? SymbolShape.values.byName(json['requiredShape'] as String)
          : null,
      requiredColor: color,
    );
  }

  Map<String, dynamic> toJson() {
    String? colorHex;
    if (requiredColor != null) {
      colorHex =
          '#${requiredColor!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    }
    return {
      'mode': mode.name,
      if (requiredShape != null) 'requiredShape': requiredShape!.name,
      if (colorHex != null) 'requiredColor': colorHex,
    };
  }

  AttackEligibilityRule copyWith({
    AttackMode? mode,
    SymbolShape? requiredShape,
    Color? requiredColor,
  }) =>
      AttackEligibilityRule(
        mode: mode ?? this.mode,
        requiredShape: requiredShape ?? this.requiredShape,
        requiredColor: requiredColor ?? this.requiredColor,
      );
}
