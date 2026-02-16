import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../engine/deck_manager.dart';
import '../engine/turn_manager.dart';

/// Manages the live [GameState].
///
/// [GameState] is a mutable object — its fields are mutated in place by the
/// engine layer.  To ensure Riverpod propagates changes even when the object
/// identity is unchanged, [updateShouldNotify] is overridden to always return
/// `true`.  Every public method that modifies [state] calls [_notify] as its
/// final step so listeners are always informed.
class GameStateNotifier extends StateNotifier<GameState?> {
  GameStateNotifier() : super(null);

  /// Always notify so that mutable-state mutations are propagated.
  @override
  bool updateShouldNotify(GameState? old, GameState? current) => true;

  /// Forces a listener notification by reassigning the current state value.
  void _notify() {
    // Temporarily shadow with null so the setter doesn't short-circuit, then
    // restore.  This guarantees the ChangeNotifier fires even when the object
    // reference is identical.
    final current = state;
    // ignore: invalid_use_of_protected_member
    super.state = null;
    // ignore: invalid_use_of_protected_member
    super.state = current;
  }

  /// Initialises a fresh game from the provided configuration.
  void startGame({
    required BoardModel board,
    required DeckModel p1Deck,
    required DeckModel p2Deck,
    required GameRules rules,
  }) {
    final player1 = DeckManager.buildPlayer(PlayerOwner.red, p1Deck, rules);
    final player2 = DeckManager.buildPlayer(PlayerOwner.blue, p2Deck, rules);
    DeckManager.dealStartingHand(player1, rules);
    DeckManager.dealStartingHand(player2, rules);

    state = GameState(
      board: board.cleared(),
      player1: player1,
      player2: player2,
      rules: rules,
      phase: GamePhase.playing,
      currentTurn: PlayerOwner.red,
    );
  }

  /// Places [card] at [coord], resolves flips, then checks for game over.
  void placeCard(HexCard card, AxialCoord coord) {
    if (state == null) return;
    TurnManager.placeCard(card, coord, state!);
    _checkGameOver();
    _notify();
  }

  /// Clears pending flip events, advances the turn, and optionally auto-draws.
  void endTurn() {
    if (state == null) return;
    state!.pendingFlipEvents.clear();
    TurnManager.endTurn(state!);
    _checkGameOver();
    _notify();
  }

  /// Manually draws [rules.cardsDrawnPerTurn] cards for the current player.
  void drawCard() {
    if (state == null) return;
    state!.currentPlayer.draw(
      state!.rules.cardsDrawnPerTurn,
      handLimit: state!.rules.handLimit,
    );
    _notify();
  }

  /// Removes all pending flip events without ending the turn.
  void clearFlipEvents() {
    if (state == null) return;
    state!.pendingFlipEvents.clear();
    _notify();
  }

  /// Detects end-of-game conditions and transitions [phase] to [GamePhase.ended].
  void _checkGameOver() {
    if (state == null) return;
    if (TurnManager.isGameOver(state!)) {
      TurnManager.computeFinalScores(state!);
      state!.phase = GamePhase.ended;
    }
  }

  /// Tears down the active game session.
  void resetGame() => state = null;
}
