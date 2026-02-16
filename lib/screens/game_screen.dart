import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/widgets/app_colors.dart';
import 'package:hexflip/widgets/hex_board_widget.dart';
import 'package:hexflip/widgets/hand_widget.dart';
import 'package:hexflip/widgets/comparison_overlay.dart';
import 'package:hexflip/engine/adjacency_resolver.dart';
import 'package:hexflip/engine/hex_math.dart';
import 'package:hexflip/screens/setup_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

/// Performs a read-only adjacency preview without mutating the board.
/// This mirrors AdjacencyResolver.resolve logic but skips the flip() call.
List<AdjacencyComparison> _previewAdjacency(
  HexCard placedCard,
  AxialCoord placedCoord,
  BoardModel board,
  GameRules rules,
) {
  final comparisons = <AdjacencyComparison>[];
  for (int sideIndex = 0; sideIndex < 6; sideIndex++) {
    final neighborCoord = neighborAt(placedCoord, sideIndex);
    final neighborCell = board.cells[neighborCoord];
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

    comparisons.add(AdjacencyComparison(
      attackerCoord: placedCoord,
      defenderCoord: neighborCoord,
      attackerSideIndex: sideIndex,
      defenderSideIndex: defSideIndex,
      attackerSide: attackerSide,
      defenderSide: defenderSide,
      eligible: eligible,
      succeeds: succeeds,
      flipped: succeeds, // Will be flipped by the engine
    ));
  }
  return comparisons;
}

class _GameScreenState extends ConsumerState<GameScreen> {
  HexCard? _selectedCard;
  List<AdjacencyComparison>? _lastComparisons;
  bool _showComparisonOverlay = false;

  void _onCardSelected(HexCard card) {
    setState(() {
      _selectedCard = _selectedCard?.id == card.id ? null : card;
    });
  }

  void _onCellTapped(AxialCoord coord) {
    final gs = ref.read(gameStateProvider);
    if (gs == null) return;

    final cell = gs.board.cells[coord];
    if (cell == null || !cell.isActive) return;

    if (_selectedCard != null && cell.isEmpty) {
      final cardToPlace = _selectedCard!;
      // Compute preview comparisons BEFORE placement (read-only, no mutation)
      final placedCard = cardToPlace.copyWith(owner: gs.currentTurn);
      final comparisons = _previewAdjacency(placedCard, coord, gs.board, gs.rules);

      setState(() {
        _selectedCard = null;
      });

      // Now perform the actual placement (mutates board, flips cards)
      ref.read(gameStateProvider.notifier).placeCard(cardToPlace, coord);

      // Show overlay if any adjacency comparisons exist
      if (comparisons.isNotEmpty) {
        setState(() {
          _lastComparisons = comparisons;
          _showComparisonOverlay = true;
        });
      }
    }
  }

  void _onDismissComparison() {
    setState(() {
      _showComparisonOverlay = false;
      _lastComparisons = null;
    });
    ref.read(gameStateProvider.notifier).clearFlipEvents();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    if (gameState == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No active game',
                style: TextStyle(color: AppColors.textMuted, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back', style: TextStyle(color: AppColors.background)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Top bar
              _TopBar(gameState: gameState),
              // Board
              Expanded(
                child: HexBoardWidget(
                  cellSize: 44.0,
                  selectedTarget: null,
                  onCellTapped: _onCellTapped,
                ),
              ),
              // Bottom controls
              _BottomBar(
                onDrawCard: () => ref.read(gameStateProvider.notifier).drawCard(),
                onEndTurn: () {
                  ref.read(gameStateProvider.notifier).endTurn();
                  setState(() {
                    _selectedCard = null;
                  });
                },
              ),
              // Hand
              HandWidget(
                onCardSelected: _onCardSelected,
                selectedCardId: _selectedCard?.id,
              ),
            ],
          ),
          // Comparison overlay
          if (_showComparisonOverlay && _lastComparisons != null)
            ComparisonOverlay(
              comparisons: _lastComparisons!,
              onDismiss: _onDismissComparison,
            ),
          // Game over overlay
          if (gameState.phase == GamePhase.ended)
            _GameOverOverlay(
              gameState: gameState,
              onPlayAgain: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SetupScreen()),
                );
              },
              onMenu: () {
                ref.read(gameStateProvider.notifier).resetGame();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameState gameState;

  const _TopBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final scores = gameState.scores;
    final isRedTurn = gameState.currentTurn == PlayerOwner.red;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Player 1 score
          Expanded(
            child: _PlayerScore(
              name: gameState.player1.displayName,
              score: scores.$1,
              color: AppColors.redPlayerLight,
              isActive: isRedTurn,
              align: CrossAxisAlignment.start,
            ),
          ),
          // Turn indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRedTurn ? AppColors.redPlayerLight : AppColors.bluePlayerLight,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRedTurn
                      ? gameState.player1.displayName
                      : gameState.player2.displayName,
                  style: TextStyle(
                    color: isRedTurn ? AppColors.redPlayerLight : AppColors.bluePlayerLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Turn',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          // Player 2 score
          Expanded(
            child: _PlayerScore(
              name: gameState.player2.displayName,
              score: scores.$2,
              color: AppColors.bluePlayerLight,
              isActive: !isRedTurn,
              align: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool isActive;
  final CrossAxisAlignment align;

  const _PlayerScore({
    required this.name,
    required this.score,
    required this.color,
    required this.isActive,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          name,
          style: TextStyle(
            color: isActive ? color : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            color: isActive ? color : AppColors.textMuted,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onDrawCard;
  final VoidCallback onEndTurn;

  const _BottomBar({required this.onDrawCard, required this.onEndTurn});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.style_rounded, size: 16),
            label: const Text('Draw'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.cellBorder),
            ),
            onPressed: onDrawCard,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.skip_next_rounded, size: 16),
            label: const Text('End Turn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              foregroundColor: AppColors.text,
            ),
            onPressed: onEndTurn,
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const _GameOverOverlay({
    required this.gameState,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final scores = gameState.scores;
    final redScore = scores.$1;
    final blueScore = scores.$2;

    String winnerText;
    Color winnerColor;
    if (redScore > blueScore) {
      winnerText = '${gameState.player1.displayName} Wins!';
      winnerColor = AppColors.redPlayerLight;
    } else if (blueScore > redScore) {
      winnerText = '${gameState.player2.displayName} Wins!';
      winnerColor = AppColors.bluePlayerLight;
    } else {
      winnerText = 'Draw!';
      winnerColor = AppColors.accent;
    }

    return Container(
      color: Colors.black.withAlpha(204),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cellBorder, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.attackHighlight, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Game Over',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                winnerText,
                style: TextStyle(
                  color: winnerColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScoreDisplay(
                    label: gameState.player1.displayName,
                    score: redScore,
                    color: AppColors.redPlayerLight,
                  ),
                  const Text('vs', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                  _ScoreDisplay(
                    label: gameState.player2.displayName,
                    score: blueScore,
                    color: AppColors.bluePlayerLight,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onPlayAgain,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('Main Menu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.cellBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onMenu,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreDisplay({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const Text('cells', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
