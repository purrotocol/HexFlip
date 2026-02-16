import '../models/models.dart';
import 'flip_engine.dart';
import 'deck_manager.dart';

/// Manages the sequence of actions within a turn: placement, flip resolution,
/// turn switching, auto-draw, and game-over detection.
class TurnManager {
  TurnManager._();

  /// Returns true if a card can legally be placed at [coord] in [state].
  ///
  /// The cell must exist in the board, be active, and currently be empty.
  static bool canPlaceCard(AxialCoord coord, GameState state) {
    final cell = state.board.cells[coord];
    if (cell == null) return false;
    if (!cell.isActive) return false;
    if (cell.isOccupied) return false;
    return true;
  }

  /// Places [card] at [coord] for the current player and resolves flips.
  ///
  /// Steps:
  /// 1. Remove [card] from the current player's hand.
  /// 2. Set the cell's card, ensuring owner matches [state.currentTurn].
  /// 3. Run [FlipEngine.resolve] to evaluate and apply adjacency flips.
  /// 4. Append any resulting [FlipEvent]s to [state.pendingFlipEvents].
  /// 5. Return the full [FlipResult].
  ///
  /// Throws [StateError] if [coord] is not a valid empty cell, or if [card]
  /// is not found in the current player's hand.
  static FlipResult placeCard(
    HexCard card,
    AxialCoord coord,
    GameState state,
  ) {
    if (!canPlaceCard(coord, state)) {
      throw StateError(
          'Cannot place card at $coord: cell does not exist, is inactive, or is occupied.');
    }

    final currentPlayer = state.currentPlayer;
    final cardIndex = currentPlayer.hand.indexWhere((c) => c.id == card.id);
    if (cardIndex == -1) {
      throw StateError(
          'Card ${card.id} is not in the current player\'s hand.');
    }

    // Remove card from hand
    currentPlayer.hand.removeAt(cardIndex);

    // Place card with correct owner onto the cell
    card.owner = state.currentTurn;
    state.board.cells[coord]!.card = card;

    // Resolve adjacency flips
    final result = FlipEngine.resolve(coord, state.board, state.rules);

    // Accumulate flip events for downstream consumers
    state.pendingFlipEvents.addAll(result.flipEvents);

    return result;
  }

  /// Ends the current player's turn and prepares for the next player.
  ///
  /// Steps:
  /// 1. Switch the active turn to the other player.
  /// 2. If [GameRules.autoDrawEnabled], draw [GameRules.cardsDrawnPerTurn]
  ///    cards for the new current player, respecting [GameRules.handLimit].
  static void endTurn(GameState state) {
    state.switchTurn();

    if (state.rules.autoDrawEnabled) {
      state.currentPlayer.draw(
        state.rules.cardsDrawnPerTurn,
        handLimit: state.rules.handLimit,
      );
    }
  }

  /// Returns true if the game has ended.
  ///
  /// The game is over when either all active board cells are occupied, or
  /// both players have empty hands.
  static bool isGameOver(GameState state) {
    return state.boardFull || state.bothHandsEmpty;
  }

  /// Counts the occupied cells owned by each player and writes the totals
  /// into [Player.score].
  ///
  /// Only active cells with a card are counted.
  static void computeFinalScores(GameState state) {
    int redScore = 0;
    int blueScore = 0;

    for (final cell in state.board.cells.values) {
      if (!cell.isActive) continue;
      final card = cell.card;
      if (card == null) continue;
      if (card.owner == PlayerOwner.red) {
        redScore++;
      } else {
        blueScore++;
      }
    }

    state.player1.score = redScore;
    state.player2.score = blueScore;
  }
}
