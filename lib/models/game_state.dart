import 'board_model.dart';
import 'hex_cell.dart';
import 'card_model.dart';
import 'player.dart';
import 'rules/game_rules.dart';

enum GamePhase { setup, playing, ended }

class FlipEvent {
  final AxialCoord cellCoord;
  final PlayerOwner from;
  final PlayerOwner to;

  const FlipEvent({
    required this.cellCoord,
    required this.from,
    required this.to,
  });
}

class GameState {
  final BoardModel board;
  final Player player1; // red
  final Player player2; // blue
  PlayerOwner currentTurn;
  GamePhase phase;
  final List<FlipEvent> pendingFlipEvents;
  final GameRules rules;

  GameState({
    required this.board,
    required this.player1,
    required this.player2,
    required this.rules,
    this.currentTurn = PlayerOwner.red,
    this.phase = GamePhase.setup,
    List<FlipEvent>? pendingFlipEvents,
  }) : pendingFlipEvents = pendingFlipEvents ?? [];

  Player get currentPlayer =>
      currentTurn == PlayerOwner.red ? player1 : player2;

  Player get waitingPlayer =>
      currentTurn == PlayerOwner.red ? player2 : player1;

  void switchTurn() {
    currentTurn =
        currentTurn == PlayerOwner.red ? PlayerOwner.blue : PlayerOwner.red;
  }

  /// Count how many board cells each player owns.
  (int red, int blue) get scores {
    int red = 0, blue = 0;
    for (final cell in board.cells.values) {
      if (cell.card == null) continue;
      if (cell.card!.owner == PlayerOwner.red) {
        red++;
      } else {
        blue++;
      }
    }
    return (red, blue);
  }

  bool get boardFull => board.cells.values
      .where((c) => c.isActive)
      .every((c) => c.isOccupied);

  bool get bothHandsEmpty =>
      player1.hand.isEmpty && player2.hand.isEmpty;
}
