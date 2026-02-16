import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class GameRulesNotifier extends StateNotifier<GameRules> {
  GameRulesNotifier() : super(GameRules());

  void update(GameRules rules) => state = rules;

  void setStartingHandSize(int v) =>
      state = state.copyWith(startingHandSize: v);

  void setCardsDrawnPerTurn(int v) =>
      state = state.copyWith(cardsDrawnPerTurn: v);

  void setHandLimit(int v) => state = state.copyWith(handLimit: v);

  void setDeckSize(int v) => state = state.copyWith(deckSize: v);

  void setAutoDrawEnabled(bool v) =>
      state = state.copyWith(autoDrawEnabled: v);

  void setPlacementRequired(bool v) =>
      state = state.copyWith(placementRequired: v);

  void setAttackEligibility(AttackEligibilityRule r) =>
      state = state.copyWith(attackEligibility: r);

  void setComparisonRule(ComparisonRule r) =>
      state = state.copyWith(comparisonRule: r);
}
