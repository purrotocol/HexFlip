import 'package:uuid/uuid.dart';
import 'card_model.dart';

class DeckModel {
  final String id;
  final String name;
  final List<HexCard> cards;

  DeckModel({
    String? id,
    required this.name,
    required this.cards,
  }) : id = id ?? const Uuid().v4();

  factory DeckModel.fromJson(Map<String, dynamic> json) => DeckModel(
        id: json['id'] as String,
        name: json['name'] as String,
        cards: (json['cards'] as List)
            .map((c) => HexCard.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  DeckModel copyWith({String? name, List<HexCard>? cards}) => DeckModel(
        id: id,
        name: name ?? this.name,
        cards: cards ?? List.from(this.cards),
      );
}
