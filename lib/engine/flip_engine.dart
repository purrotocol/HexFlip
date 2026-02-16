import '../models/models.dart';
import 'adjacency_resolver.dart';

/// The aggregated result of resolving flips after a card placement.
class FlipResult {
  /// All adjacency comparisons evaluated (including non-flips).
  final List<AdjacencyComparison> comparisons;

  /// Events for every card that was actually flipped.
  final List<FlipEvent> flipEvents;

  const FlipResult({
    required this.comparisons,
    required this.flipEvents,
  });
}

/// Orchestrates flip resolution for a placed card.
class FlipEngine {
  /// Resolves all adjacency comparisons for the card at [placedCoord].
  ///
  /// Delegates comparison logic to [AdjacencyResolver], then wraps each
  /// successful flip into a [FlipEvent] for downstream consumers (UI,
  /// animation queues, history logs).
  static FlipResult resolve(
    AxialCoord placedCoord,
    BoardModel board,
    GameRules rules,
  ) {
    final comparisons = AdjacencyResolver.resolve(placedCoord, board, rules);

    final flipEvents = <FlipEvent>[];
    for (final comparison in comparisons) {
      if (comparison.flipped) {
        // The card has already been flipped in place by AdjacencyResolver.
        // The 'from' owner is the owner before flip, 'to' is after.
        // Because flip() toggles the owner, the current owner on the card is
        // now the attacker's owner. The defender's prior owner is the opposite.
        final toOwner = board.cells[comparison.defenderCoord]!.card!.owner;
        final fromOwner =
            toOwner == PlayerOwner.red ? PlayerOwner.blue : PlayerOwner.red;

        flipEvents.add(FlipEvent(
          cellCoord: comparison.defenderCoord,
          from: fromOwner,
          to: toOwner,
        ));
      }
    }

    return FlipResult(comparisons: comparisons, flipEvents: flipEvents);
  }
}
