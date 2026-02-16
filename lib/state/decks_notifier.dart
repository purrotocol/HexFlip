import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class DecksNotifier extends StateNotifier<Map<String, DeckModel>> {
  DecksNotifier() : super({});

  void addOrUpdateDeck(DeckModel deck) {
    state = {...state, deck.id: deck};
  }

  void removeDeck(String id) {
    final updated = Map<String, DeckModel>.from(state);
    updated.remove(id);
    state = updated;
  }

  void loadDecks(Map<String, DeckModel> decks) => state = decks;
}
