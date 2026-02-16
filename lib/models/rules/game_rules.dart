import 'attack_eligibility.dart';
import 'comparison_rule.dart';

class GameRules {
  int startingHandSize;
  int cardsDrawnPerTurn;
  int handLimit;
  int deckSize;
  bool autoDrawEnabled;
  bool placementRequired;
  AttackEligibilityRule attackEligibility;
  ComparisonRule comparisonRule;

  GameRules({
    this.startingHandSize = 5,
    this.cardsDrawnPerTurn = 1,
    this.handLimit = 7,
    this.deckSize = 20,
    this.autoDrawEnabled = true,
    this.placementRequired = true,
    AttackEligibilityRule? attackEligibility,
    ComparisonRule? comparisonRule,
  })  : attackEligibility = attackEligibility ?? const AttackEligibilityRule(),
        comparisonRule = comparisonRule ?? const ComparisonRule();

  factory GameRules.fromJson(Map<String, dynamic> json) => GameRules(
        startingHandSize: json['startingHandSize'] as int? ?? 5,
        cardsDrawnPerTurn: json['cardsDrawnPerTurn'] as int? ?? 1,
        handLimit: json['handLimit'] as int? ?? 7,
        deckSize: json['deckSize'] as int? ?? 20,
        autoDrawEnabled: json['autoDrawEnabled'] as bool? ?? true,
        placementRequired: json['placementRequired'] as bool? ?? true,
        attackEligibility: json['attackEligibility'] != null
            ? AttackEligibilityRule.fromJson(
                json['attackEligibility'] as Map<String, dynamic>)
            : const AttackEligibilityRule(),
        comparisonRule: json['comparison'] != null
            ? ComparisonRule.fromJson(
                json['comparison'] as Map<String, dynamic>)
            : const ComparisonRule(),
      );

  Map<String, dynamic> toJson() => {
        'startingHandSize': startingHandSize,
        'cardsDrawnPerTurn': cardsDrawnPerTurn,
        'handLimit': handLimit,
        'deckSize': deckSize,
        'autoDrawEnabled': autoDrawEnabled,
        'placementRequired': placementRequired,
        'attackEligibility': attackEligibility.toJson(),
        'comparison': comparisonRule.toJson(),
      };

  GameRules copyWith({
    int? startingHandSize,
    int? cardsDrawnPerTurn,
    int? handLimit,
    int? deckSize,
    bool? autoDrawEnabled,
    bool? placementRequired,
    AttackEligibilityRule? attackEligibility,
    ComparisonRule? comparisonRule,
  }) =>
      GameRules(
        startingHandSize: startingHandSize ?? this.startingHandSize,
        cardsDrawnPerTurn: cardsDrawnPerTurn ?? this.cardsDrawnPerTurn,
        handLimit: handLimit ?? this.handLimit,
        deckSize: deckSize ?? this.deckSize,
        autoDrawEnabled: autoDrawEnabled ?? this.autoDrawEnabled,
        placementRequired: placementRequired ?? this.placementRequired,
        attackEligibility: attackEligibility ?? this.attackEligibility,
        comparisonRule: comparisonRule ?? this.comparisonRule,
      );
}
