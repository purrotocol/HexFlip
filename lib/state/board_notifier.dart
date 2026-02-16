import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

class BoardNotifier extends StateNotifier<BoardModel> {
  /// Default: classic 19-cell board (center + 2 rings).
  BoardNotifier() : super(_buildClassic19());

  static BoardModel _buildClassic19() {
    // Build a classic 19-hex board using axial coordinates.
    // Includes center (0,0) + ring 1 (6 cells) + ring 2 (12 cells).
    // A cell (q, r) is within 2 rings when max(|q|, |r|, |q+r|) <= 2.
    final coords = <AxialCoord>[];
    for (int q = -2; q <= 2; q++) {
      for (int r = -2; r <= 2; r++) {
        if ((q + r).abs() <= 2) coords.add(AxialCoord(q, r));
      }
    }
    final cells = <AxialCoord, HexCell>{};
    for (final c in coords) {
      cells[c] = HexCell(coord: c, isActive: true);
    }
    return BoardModel(id: 'classic_19', name: 'Classic 19', cells: cells);
  }

  void loadBoard(BoardModel board) => state = board;

  void toggleCell(AxialCoord coord) {
    final newCells = Map<AxialCoord, HexCell>.from(state.cells);
    if (newCells.containsKey(coord)) {
      final cell = newCells[coord]!;
      newCells[coord] =
          HexCell(coord: coord, isActive: !cell.isActive, card: cell.card);
    } else {
      newCells[coord] = HexCell(coord: coord, isActive: true);
    }
    state = state.copyWith(cells: newCells);
  }

  void setName(String name) => state = state.copyWith(name: name);

  void clearCards() => state = state.cleared();
}
