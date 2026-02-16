import 'package:uuid/uuid.dart';
import 'card_side.dart';

enum PlayerOwner { red, blue }

class HexCard {
  final String id;
  final List<CardSide> sides; // length == 6, index 0 = top-right edge, clockwise
  PlayerOwner owner;

  HexCard({
    String? id,
    required this.sides,
    this.owner = PlayerOwner.red,
  })  : id = id ?? const Uuid().v4(),
        assert(sides.length == 6, 'HexCard must have exactly 6 sides');

  void flip() {
    owner = owner == PlayerOwner.red ? PlayerOwner.blue : PlayerOwner.red;
  }

  factory HexCard.fromJson(Map<String, dynamic> json) => HexCard(
        id: json['id'] as String,
        sides: (json['sides'] as List)
            .map((s) => CardSide.fromJson(s as Map<String, dynamic>))
            .toList(),
        owner: json['owner'] != null
            ? PlayerOwner.values.byName(json['owner'] as String)
            : PlayerOwner.red,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sides': sides.map((s) => s.toJson()).toList(),
        'owner': owner.name,
      };

  HexCard copyWith({List<CardSide>? sides, PlayerOwner? owner}) => HexCard(
        id: id,
        sides: sides ?? List.from(this.sides),
        owner: owner ?? this.owner,
      );

  /// Returns a fresh copy with the same sides but owner reset to red.
  HexCard freshCopy() => HexCard(sides: List.from(sides), owner: PlayerOwner.red);
}
