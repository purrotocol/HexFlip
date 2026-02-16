import 'card_model.dart';

class Player {
  final PlayerOwner owner;
  List<HexCard> hand;
  List<HexCard> deck;
  int score;

  Player({
    required this.owner,
    List<HexCard>? hand,
    List<HexCard>? deck,
  })  : hand = hand ?? [],
        deck = deck ?? [],
        score = 0;

  String get displayName => owner == PlayerOwner.red ? 'Player 1' : 'Player 2';

  bool get canDraw => deck.isNotEmpty;

  /// Draw one card. Returns the card or null if deck is empty.
  HexCard? drawOne() {
    if (deck.isEmpty) return null;
    final card = deck.removeAt(0);
    hand.add(card);
    return card;
  }

  /// Draw n cards up to handLimit. Returns drawn cards.
  List<HexCard> draw(int count, {int handLimit = 999}) {
    final drawn = <HexCard>[];
    while (drawn.length < count && deck.isNotEmpty && hand.length < handLimit) {
      drawn.add(drawOne()!);
    }
    return drawn;
  }

  /// Recount score based on cards on the board (called externally).
  void resetScore() => score = 0;
}
