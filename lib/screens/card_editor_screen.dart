import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/widgets/app_colors.dart';

// 12 preset colors for the color picker
const List<Color> _presetColors = [
  Color(0xFF000000), // black
  Color(0xFFFFFFFF), // white
  Color(0xFFCC0000), // red
  Color(0xFF0044CC), // blue
  Color(0xFF007700), // green
  Color(0xFFFFCC00), // yellow
  Color(0xFFFF8800), // orange
  Color(0xFF880088), // purple
  Color(0xFF00AACC), // cyan
  Color(0xFFCC0066), // pink
  Color(0xFF888888), // gray
  Color(0xFF884422), // brown
];

const List<String> _presetColorNames = [
  'Black', 'White', 'Red', 'Blue', 'Green', 'Yellow',
  'Orange', 'Purple', 'Cyan', 'Pink', 'Gray', 'Brown',
];

class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  String? _selectedDeckId;
  // Local mutable copy of the selected deck's cards
  List<HexCard> _editingCards = [];
  String _editingDeckName = '';
  final _deckNameController = TextEditingController();

  @override
  void dispose() {
    _deckNameController.dispose();
    super.dispose();
  }

  void _selectDeck(String deckId, Map<String, DeckModel> decks) {
    final deck = decks[deckId];
    if (deck == null) return;
    setState(() {
      _selectedDeckId = deckId;
      _editingCards = deck.cards.map((c) => c.copyWith()).toList();
      _editingDeckName = deck.name;
      _deckNameController.text = deck.name;
    });
  }

  void _newDeck() {
    final newDeck = DeckModel(
      id: const Uuid().v4(),
      name: 'New Deck',
      cards: [],
    );
    ref.read(decksProvider.notifier).addOrUpdateDeck(newDeck);
    setState(() {
      _selectedDeckId = newDeck.id;
      _editingCards = [];
      _editingDeckName = newDeck.name;
      _deckNameController.text = newDeck.name;
    });
  }

  void _deleteDeck(String deckId) {
    ref.read(decksProvider.notifier).removeDeck(deckId);
    setState(() {
      _selectedDeckId = null;
      _editingCards = [];
      _editingDeckName = '';
      _deckNameController.text = '';
    });
  }

  void _saveDeck() {
    final id = _selectedDeckId;
    if (id == null) return;
    final deck = DeckModel(
      id: id,
      name: _editingDeckName.isEmpty ? 'Unnamed Deck' : _editingDeckName,
      cards: _editingCards,
    );
    ref.read(decksProvider.notifier).addOrUpdateDeck(deck);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deck "${deck.name}" saved'),
        backgroundColor: AppColors.surfaceAlt,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addCard() {
    final newCard = HexCard(
      sides: List.generate(
        6,
        (_) => const CardSide(
          shape: SymbolShape.circle,
          number: 1,
          shapeColor: Color(0xFFCC0000),
          numberColor: Color(0xFFFFFFFF),
        ),
      ),
      owner: PlayerOwner.red,
    );
    setState(() {
      _editingCards = [..._editingCards, newCard];
    });
  }

  void _deleteCard(int index) {
    setState(() {
      final updated = List<HexCard>.from(_editingCards);
      updated.removeAt(index);
      _editingCards = updated;
    });
  }

  void _updateCard(int cardIndex, HexCard updatedCard) {
    setState(() {
      final updated = List<HexCard>.from(_editingCards);
      updated[cardIndex] = updatedCard;
      _editingCards = updated;
    });
  }

  void _updateSide(int cardIndex, int sideIndex, CardSide updatedSide) {
    final card = _editingCards[cardIndex];
    final newSides = List<CardSide>.from(card.sides);
    newSides[sideIndex] = updatedSide;
    _updateCard(cardIndex, card.copyWith(sides: newSides));
  }

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(decksProvider);
    final deckList = decks.values.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Card Editor', style: TextStyle(color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          if (_selectedDeckId != null)
            TextButton.icon(
              icon: const Icon(Icons.save_rounded, color: AppColors.accent),
              label: const Text('Save', style: TextStyle(color: AppColors.accent)),
              onPressed: _saveDeck,
            ),
        ],
      ),
      body: Row(
        children: [
          // Left panel: deck list
          Container(
            width: 220,
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Decks',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, color: AppColors.accent),
                        tooltip: 'New Deck',
                        onPressed: _newDeck,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.cellBorder, height: 1),
                Expanded(
                  child: deckList.isEmpty
                      ? const Center(
                          child: Text(
                            'No decks.\nTap + to create.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          itemCount: deckList.length,
                          itemBuilder: (context, index) {
                            final deck = deckList[index];
                            final isSelected = deck.id == _selectedDeckId;
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: AppColors.surfaceAlt,
                              title: Text(
                                deck.name,
                                style: TextStyle(
                                  color: isSelected ? AppColors.accent : AppColors.text,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${deck.cards.length} cards',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16),
                                color: AppColors.textMuted,
                                onPressed: () => _showDeleteDeckDialog(deck.id, deck.name),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              onTap: () => _selectDeck(deck.id, decks),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.cellBorder),
          // Right panel: card editor
          Expanded(
            child: _selectedDeckId == null
                ? const Center(
                    child: Text(
                      'Select a deck to edit',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      // Deck name + controls
                      Container(
                        color: AppColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _deckNameController,
                                style: const TextStyle(color: AppColors.text, fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: 'Deck Name',
                                  labelStyle: TextStyle(color: AppColors.textMuted),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.cellBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.accent),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (v) => setState(() => _editingDeckName = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_card_rounded, size: 18),
                              label: const Text('Add Card'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceAlt,
                                foregroundColor: AppColors.text,
                              ),
                              onPressed: _addCard,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.cellBorder),
                      // Card list
                      Expanded(
                        child: _editingCards.isEmpty
                            ? const Center(
                                child: Text(
                                  'No cards. Tap "Add Card" to create one.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _editingCards.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, cardIndex) {
                                  return _CardEditorRow(
                                    card: _editingCards[cardIndex],
                                    cardIndex: cardIndex,
                                    onDelete: () => _deleteCard(cardIndex),
                                    onSideChanged: (sideIndex, side) =>
                                        _updateSide(cardIndex, sideIndex, side),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDeckDialog(String deckId, String deckName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Deck', style: TextStyle(color: AppColors.text)),
        content: Text(
          'Delete "$deckName"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteDeck(deckId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CardEditorRow extends StatelessWidget {
  final HexCard card;
  final int cardIndex;
  final VoidCallback onDelete;
  final void Function(int sideIndex, CardSide side) onSideChanged;

  const _CardEditorRow({
    required this.card,
    required this.cardIndex,
    required this.onDelete,
    required this.onSideChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Card ${cardIndex + 1}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete Card',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 6 side editors in a 2x3 grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(6, (sideIndex) {
              return _SideEditor(
                sideIndex: sideIndex,
                side: card.sides[sideIndex],
                onChanged: (updatedSide) => onSideChanged(sideIndex, updatedSide),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SideEditor extends StatelessWidget {
  final int sideIndex;
  final CardSide side;
  final void Function(CardSide) onChanged;

  const _SideEditor({
    required this.sideIndex,
    required this.side,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cellBorder.withAlpha(128)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Side ${sideIndex + 1}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Shape:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButton<SymbolShape>(
                  value: side.shape,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  isDense: true,
                  underline: Container(height: 1, color: AppColors.cellBorder),
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                  items: SymbolShape.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_shapeName(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (s) {
                    if (s != null) onChanged(side.copyWith(shape: s));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Number:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 60,
                child: _NumberField(
                  value: side.number,
                  min: 1,
                  max: 9,
                  onChanged: (n) => onChanged(side.copyWith(number: n)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Shape Color:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 6),
              _ColorSwatch(
                selectedColor: side.shapeColor,
                onSelected: (c) => onChanged(side.copyWith(shapeColor: c)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Number Color:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 6),
              _ColorSwatch(
                selectedColor: side.numberColor,
                onSelected: (c) => onChanged(side.copyWith(numberColor: c)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shapeName(SymbolShape shape) {
    switch (shape) {
      case SymbolShape.circle:
        return 'Circle';
      case SymbolShape.square:
        return 'Square';
      case SymbolShape.triangle:
        return 'Triangle';
      case SymbolShape.star:
        return 'Star';
      case SymbolShape.diamond:
        return 'Diamond';
    }
  }
}

class _NumberField extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _NumberField({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.text, fontSize: 13),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.cellBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
        ),
        isDense: true,
      ),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) {
          final clamped = parsed.clamp(widget.min, widget.max);
          widget.onChanged(clamped);
        }
      },
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color selectedColor;
  final void Function(Color) onSelected;

  const _ColorSwatch({required this.selectedColor, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.accent,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Pick Color', style: TextStyle(color: AppColors.text)),
        content: SizedBox(
          width: 240,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _presetColors.length,
            itemBuilder: (context, index) {
              final color = _presetColors[index];
              final isSelected = color.value == selectedColor.value;
              return Tooltip(
                message: _presetColorNames[index],
                child: GestureDetector(
                  onTap: () {
                    onSelected(color);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.cellBorder,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
