import '../models/models.dart';
import 'hex_math.dart';

/// Result of comparing one attacking side against one defending side.
class AdjacencyComparison {
  final AxialCoord attackerCoord;
  final AxialCoord defenderCoord;

  /// Which side of the placed card faces the neighbor.
  final int attackerSideIndex;

  /// Which side of the neighbor card faces the placed card.
  final int defenderSideIndex;

  final CardSide attackerSide;
  final CardSide defenderSide;

  /// Whether the attack eligibility rule passed for the attacker's side.
  final bool eligible;

  /// Whether the comparison rule passed (and ownership differs).
  final bool succeeds;

  /// Whether a flip was actually applied to the defender card.
  final bool flipped;

  const AdjacencyComparison({
    required this.attackerCoord,
    required this.defenderCoord,
    required this.attackerSideIndex,
    required this.defenderSideIndex,
    required this.attackerSide,
    required this.defenderSide,
    required this.eligible,
    required this.succeeds,
    required this.flipped,
  });
}

/// Resolves all adjacency comparisons for a newly placed card.
class AdjacencyResolver {
  /// Evaluates all 6 directions from [placedCoord] on [board] under [rules].
  ///
  /// For each direction:
  /// - If a neighbor cell exists, is active, and holds a card with a different
  ///   owner, the attacker side and defender side are compared.
  /// - If eligible and successful, the defender card is flipped in place.
  ///
  /// Returns a list of [AdjacencyComparison] for every direction that has a
  /// qualifying opponent card. Directions with no opponent are omitted.
  static List<AdjacencyComparison> resolve(
    AxialCoord placedCoord,
    BoardModel board,
    GameRules rules,
  ) {
    final placedCell = board.cells[placedCoord];
    if (placedCell == null || placedCell.card == null) return const [];

    final placedCard = placedCell.card!;
    final comparisons = <AdjacencyComparison>[];

    for (int sideIndex = 0; sideIndex < 6; sideIndex++) {
      final neighborCoord = neighborAt(placedCoord, sideIndex);
      final neighborCell = board.cells[neighborCoord];

      // Skip if no cell, inactive cell, empty cell, or same owner
      if (neighborCell == null) continue;
      if (!neighborCell.isActive) continue;
      if (neighborCell.card == null) continue;
      if (neighborCell.card!.owner == placedCard.owner) continue;

      final defSideIndex = oppositeSide(sideIndex);
      final attackerSide = placedCard.sides[sideIndex];
      final defenderSide = neighborCell.card!.sides[defSideIndex];

      final eligible = rules.attackEligibility.sideCanAttack(attackerSide);
      final succeeds =
          eligible && rules.comparisonRule.attackSucceeds(attackerSide, defenderSide);

      bool flipped = false;
      if (succeeds) {
        neighborCell.card!.flip();
        flipped = true;
      }

      comparisons.add(AdjacencyComparison(
        attackerCoord: placedCoord,
        defenderCoord: neighborCoord,
        attackerSideIndex: sideIndex,
        defenderSideIndex: defSideIndex,
        attackerSide: attackerSide,
        defenderSide: defenderSide,
        eligible: eligible,
        succeeds: succeeds,
        flipped: flipped,
      ));
    }

    return comparisons;
  }
}
