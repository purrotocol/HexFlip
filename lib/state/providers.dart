import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'game_rules_notifier.dart';
import 'board_notifier.dart';
import 'decks_notifier.dart';
import 'game_state_notifier.dart';
import 'setup_deck_selection_notifier.dart';

/// Holds the active [GameRules] being edited or used during setup and gameplay.
final gameRulesProvider = StateNotifierProvider<GameRulesNotifier, GameRules>(
  (ref) => GameRulesNotifier(),
);

/// Holds the active [BoardModel] used for the current editing session or game.
final activeBoardProvider =
    StateNotifierProvider<BoardNotifier, BoardModel>(
  (ref) => BoardNotifier(),
);

/// Map of saved deck id → [DeckModel], representing all persisted decks.
final decksProvider =
    StateNotifierProvider<DecksNotifier, Map<String, DeckModel>>(
  (ref) => DecksNotifier(),
);

/// The live game state. Null indicates no game is currently in progress.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState?>(
  (ref) => GameStateNotifier(),
);

/// Records which deck each player has selected during the game-setup flow.
final setupDeckSelectionProvider = StateNotifierProvider<
    SetupDeckSelectionNotifier, ({String? p1DeckId, String? p2DeckId})>(
  (ref) => SetupDeckSelectionNotifier(),
);
