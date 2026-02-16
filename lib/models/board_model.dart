import 'package:uuid/uuid.dart';
import 'hex_cell.dart';
import 'card_model.dart';

class BoardModel {
  final String id;
  final String name;
  final Map<AxialCoord, HexCell> cells;

  BoardModel({
    String? id,
    required this.name,
    required this.cells,
  }) : id = id ?? const Uuid().v4();

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    final cellList = json['cells'] as List;
    final cells = <AxialCoord, HexCell>{};
    for (final c in cellList) {
      final coord = AxialCoord.fromJson(c as Map<String, dynamic>);
      cells[coord] = HexCell(coord: coord, isActive: true);
    }
    return BoardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      cells: cells,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cells': cells.values
            .where((c) => c.isActive)
            .map((c) => c.coord.toJson())
            .toList(),
      };

  BoardModel copyWith({String? name, Map<AxialCoord, HexCell>? cells}) =>
      BoardModel(
        id: id,
        name: name ?? this.name,
        cells: cells ?? Map.from(this.cells),
      );

  /// Returns a deep copy with all cards removed.
  BoardModel cleared() {
    final newCells = <AxialCoord, HexCell>{};
    for (final entry in cells.entries) {
      newCells[entry.key] = HexCell(
        coord: entry.value.coord,
        isActive: entry.value.isActive,
      );
    }
    return BoardModel(id: id, name: name, cells: newCells);
  }

  List<AxialCoord> get activeCoords =>
      cells.values.where((c) => c.isActive).map((c) => c.coord).toList();
}
