import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/screens/game_screen.dart';
import 'package:hexflip/widgets/app_colors.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  String? _selectedBoardId;
  String? _p1DeckId;
  String? _p2DeckId;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(activeBoardProvider);
    final decks = ref.watch(decksProvider);
    final rules = ref.watch(gameRulesProvider);
    final deckList = decks.values.toList();

    // Default board selection to active board
    _selectedBoardId ??= board.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Game Setup', style: TextStyle(color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader('Board'),
            const SizedBox(height: 8),
            _buildBoardSelector(board),
            const SizedBox(height: 24),
            _SectionHeader('Player 1 Deck (Red)'),
            const SizedBox(height: 8),
            _buildDeckSelector(
              deckList,
              _p1DeckId,
              (id) => setState(() => _p1DeckId = id),
              'No deck selected',
            ),
            const SizedBox(height: 24),
            _SectionHeader('Player 2 Deck (Blue)'),
            const SizedBox(height: 8),
            _buildDeckSelector(
              deckList,
              _p2DeckId,
              (id) => setState(() => _p2DeckId = id),
              'No deck selected',
            ),
            const SizedBox(height: 24),
            _SectionHeader('Rules Summary'),
            const SizedBox(height: 8),
            _buildRulesSummary(rules),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 280,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Game', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _canStart(deckList)
                      ? () => _startGame(board, decks, rules)
                      : null,
                ),
              ),
            ),
            if (!_canStart(deckList))
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    'Select two decks to start',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canStart(List<DeckModel> deckList) =>
      deckList.isNotEmpty && _p1DeckId != null && _p2DeckId != null;

  Widget _buildBoardSelector(BoardModel activeBoard) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.grid_on_rounded, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activeBoard.name,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
            ),
          ),
          Text(
            '${activeBoard.activeCoords.length} cells',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckSelector(
    List<DeckModel> deckList,
    String? selectedId,
    void Function(String?) onChanged,
    String hint,
  ) {
    if (deckList.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cellBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No decks available. Create a deck in Card Editor.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<String>(
        value: selectedId,
        isExpanded: true,
        dropdownColor: AppColors.surfaceAlt,
        underline: const SizedBox.shrink(),
        hint: Text(hint, style: const TextStyle(color: AppColors.textMuted)),
        items: deckList
            .map(
              (d) => DropdownMenuItem(
                value: d.id,
                child: Row(
                  children: [
                    const Icon(Icons.style_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Text(d.name, style: const TextStyle(color: AppColors.text)),
                    const SizedBox(width: 8),
                    Text(
                      '(${d.cards.length} cards)',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRulesSummary(GameRules rules) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RuleRow('Starting Hand Size', '${rules.startingHandSize}'),
          _RuleRow('Cards Drawn Per Turn', '${rules.cardsDrawnPerTurn}'),
          _RuleRow('Hand Limit', '${rules.handLimit}'),
          _RuleRow('Deck Size', '${rules.deckSize}'),
          _RuleRow('Auto Draw', rules.autoDrawEnabled ? 'Yes' : 'No'),
          _RuleRow('Placement Required', rules.placementRequired ? 'Yes' : 'No'),
          _RuleRow('Attack Mode', _attackModeName(rules.attackEligibility.mode)),
          _RuleRow(
            'Win Condition',
            rules.comparisonRule.requireNumberGreater ? 'Number Greater' : 'Custom',
          ),
        ],
      ),
    );
  }

  String _attackModeName(AttackMode mode) {
    switch (mode) {
      case AttackMode.allSides:
        return 'All Sides';
      case AttackMode.specificShape:
        return 'Specific Shape';
      case AttackMode.specificColor:
        return 'Specific Color';
      case AttackMode.shapeAndColor:
        return 'Shape + Color';
    }
  }

  void _startGame(BoardModel board, Map<String, DeckModel> decks, GameRules rules) {
    final p1Deck = decks[_p1DeckId!]!;
    final p2Deck = decks[_p2DeckId!]!;

    ref.read(gameStateProvider.notifier).startGame(
          board: board,
          p1Deck: p1Deck,
          p2Deck: p2Deck,
          rules: rules,
        );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final String value;
  const _RuleRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 13)),
        ],
      ),
    );
  }
}
