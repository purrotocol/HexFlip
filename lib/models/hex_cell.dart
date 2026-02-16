import 'package:flutter/foundation.dart';
import 'card_model.dart';

@immutable
class AxialCoord {
  final int q;
  final int r;

  const AxialCoord(this.q, this.r);

  /// The six axial direction vectors, indexed to match HexCard side indices:
  /// 0=top-right, 1=right, 2=bottom-right, 3=bottom-left, 4=left, 5=top-left
  static const List<AxialCoord> directions = [
    AxialCoord(1, -1), // 0: top-right
    AxialCoord(1, 0),  // 1: right
    AxialCoord(0, 1),  // 2: bottom-right
    AxialCoord(-1, 1), // 3: bottom-left
    AxialCoord(-1, 0), // 4: left
    AxialCoord(0, -1), // 5: top-left
  ];

  AxialCoord operator +(AxialCoord other) => AxialCoord(q + other.q, r + other.r);

  @override
  bool operator ==(Object other) =>
      other is AxialCoord && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'AxialCoord($q, $r)';

  Map<String, dynamic> toJson() => {'q': q, 'r': r};
  factory AxialCoord.fromJson(Map<String, dynamic> json) =>
      AxialCoord(json['q'] as int, json['r'] as int);
}

class HexCell {
  final AxialCoord coord;
  bool isActive;
  HexCard? card;

  HexCell({required this.coord, this.isActive = true, this.card});

  bool get isEmpty => card == null;
  bool get isOccupied => card != null;
}
