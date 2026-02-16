import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetupDeckSelectionNotifier
    extends StateNotifier<({String? p1DeckId, String? p2DeckId})> {
  SetupDeckSelectionNotifier() : super((p1DeckId: null, p2DeckId: null));

  void selectP1Deck(String? id) =>
      state = (p1DeckId: id, p2DeckId: state.p2DeckId);

  void selectP2Deck(String? id) =>
      state = (p1DeckId: state.p1DeckId, p2DeckId: id);

  void reset() => state = (p1DeckId: null, p2DeckId: null);
}
