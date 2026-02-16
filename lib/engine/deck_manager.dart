import 'dart:math';
import '../models/models.dart';

/// Handles deck construction, shuffling, and starting-hand dealing.
class DeckManager {
  DeckManager._();

  /// Returns a new list containing the same cards in a random order.
  /// Does not mutate the original list.
  static List<HexCard> shuffle(List<HexCard> cards) {
    final copy = List<HexCard>.from(cards);
    copy.shuffle(Random());
    return copy;
  }

  /// Builds a [Player] from a [DeckModel] template, applying [rules].
  ///
  /// Steps:
  /// 1. Take up to [GameRules.deckSize] cards from [deckTemplate].
  /// 2. Call [HexCard.freshCopy] on each card, then set the correct [owner].
  /// 3. Shuffle the resulting deck.
  /// 4. Return a [Player] with the shuffled deck and an empty hand.
  static Player buildPlayer(
    PlayerOwner owner,
    DeckModel deckTemplate,
    GameRules rules,
  ) {
    final sourceCards = deckTemplate.cards.take(rules.deckSize).toList();

    final deckCards = sourceCards.map((card) {
      final fresh = card.freshCopy();
      fresh.owner = owner;
      return fresh;
    }).toList();

    final shuffledDeck = shuffle(deckCards);

    return Player(
      owner: owner,
      deck: shuffledDeck,
      hand: [],
    );
  }

  /// Deals the starting hand for [player] according to [rules].
  ///
  /// Draws [GameRules.startingHandSize] cards, respecting [GameRules.handLimit].
  static void dealStartingHand(Player player, GameRules rules) {
    player.draw(rules.startingHandSize, handLimit: rules.handLimit);
  }
}
