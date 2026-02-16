import 'dart:ui';

enum SymbolShape { circle, square, triangle, star, diamond }

class CardSide {
  final SymbolShape shape;
  final int number;
  final Color shapeColor;
  final Color numberColor;

  const CardSide({
    required this.shape,
    required this.number,
    required this.shapeColor,
    required this.numberColor,
  });

  factory CardSide.fromJson(Map<String, dynamic> json) => CardSide(
        shape: SymbolShape.values.byName(json['shape'] as String),
        number: json['number'] as int,
        shapeColor: _colorFromHex(json['shapeColor'] as String),
        numberColor: _colorFromHex(json['numberColor'] as String),
      );

  Map<String, dynamic> toJson() => {
        'shape': shape.name,
        'number': number,
        'shapeColor': _colorToHex(shapeColor),
        'numberColor': _colorToHex(numberColor),
      };

  static Color _colorFromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }

  static String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  CardSide copyWith({
    SymbolShape? shape,
    int? number,
    Color? shapeColor,
    Color? numberColor,
  }) =>
      CardSide(
        shape: shape ?? this.shape,
        number: number ?? this.number,
        shapeColor: shapeColor ?? this.shapeColor,
        numberColor: numberColor ?? this.numberColor,
      );
}
