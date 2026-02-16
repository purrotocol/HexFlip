import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/engine/hex_math.dart';
import 'package:hexflip/widgets/app_colors.dart';

class BoardEditorScreen extends ConsumerStatefulWidget {
  const BoardEditorScreen({super.key});

  @override
  ConsumerState<BoardEditorScreen> createState() => _BoardEditorScreenState();
}

class _BoardEditorScreenState extends ConsumerState<BoardEditorScreen> {
  static const double _cellSize = 48.0;
  // Range of hexes to display: q and r from -4 to 4, filter |q+r|<=5
  static const int _range = 4;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(activeBoardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(board.name, style: const TextStyle(color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open_rounded, color: AppColors.accent),
            tooltip: 'Load Board',
            onPressed: () => _showLoadBoardDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.save_rounded, color: AppColors.accent),
            tooltip: 'Save Board',
            onPressed: () => _showSaveBoardDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Tap hexagons to toggle active cells',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${board.activeCoords.length} active cells',
                  style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cellBorder),
          // Hex grid
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 0.4,
              maxScale: 3.0,
              child: Center(
                child: _HexGridEditor(
                  board: board,
                  cellSize: _cellSize,
                  range: _range,
                  onCellToggled: (coord) {
                    ref.read(activeBoardProvider.notifier).toggleCell(coord);
                  },
                ),
              ),
            ),
          ),
          // Legend
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppColors.cellActive, label: 'Active'),
                const SizedBox(width: 24),
                _LegendItem(color: AppColors.cellInactive, label: 'Inactive'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveBoardDialog(BuildContext context) {
    final board = ref.read(activeBoardProvider);
    final nameController = TextEditingController(text: board.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Save Board', style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
            labelText: 'Board Name',
            labelStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.cellBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(activeBoardProvider.notifier).setName(name);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Board "${nameController.text}" saved'),
                  backgroundColor: AppColors.surfaceAlt,
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: AppColors.background)),
          ),
        ],
      ),
    );
  }

  void _showLoadBoardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Load Board', style: TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LoadBoardOption(
              name: 'Classic 19',
              description: 'Standard 19-cell board (2 rings)',
              onTap: () {
                _loadClassic19();
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _LoadBoardOption(
              name: 'Small 7',
              description: 'Compact 7-cell board (1 ring)',
              onTap: () {
                _loadSmall7();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  void _loadClassic19() {
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
    final board = BoardModel(id: 'classic_19', name: 'Classic 19', cells: cells);
    ref.read(activeBoardProvider.notifier).loadBoard(board);
  }

  void _loadSmall7() {
    final coords = <AxialCoord>[];
    for (int q = -1; q <= 1; q++) {
      for (int r = -1; r <= 1; r++) {
        if ((q + r).abs() <= 1) coords.add(AxialCoord(q, r));
      }
    }
    final cells = <AxialCoord, HexCell>{};
    for (final c in coords) {
      cells[c] = HexCell(coord: c, isActive: true);
    }
    final board = BoardModel(id: 'small_7', name: 'Small 7', cells: cells);
    ref.read(activeBoardProvider.notifier).loadBoard(board);
  }
}

class _HexGridEditor extends StatelessWidget {
  final BoardModel board;
  final double cellSize;
  final int range;
  final void Function(AxialCoord) onCellToggled;

  const _HexGridEditor({
    required this.board,
    required this.cellSize,
    required this.range,
    required this.onCellToggled,
  });

  @override
  Widget build(BuildContext context) {
    // Build list of all coords in range
    final coordsInRange = <AxialCoord>[];
    for (int q = -range; q <= range; q++) {
      for (int r = -range; r <= range; r++) {
        if ((q + r).abs() <= range + 1) {
          coordsInRange.add(AxialCoord(q, r));
        }
      }
    }

    // Calculate bounds to size the widget
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final coord in coordsInRange) {
      final offset = hexToPixel(coord, cellSize);
      minX = min(minX, offset.dx);
      maxX = max(maxX, offset.dx);
      minY = min(minY, offset.dy);
      maxY = max(maxY, offset.dy);
    }

    final padding = cellSize * 1.2;
    final width = maxX - minX + padding * 2;
    final height = maxY - minY + padding * 2;
    final originX = -minX + padding;
    final originY = -minY + padding;

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTapDown: (details) {
          final localPos = details.localPosition;
          // Convert tap position to axial coord, accounting for origin offset
          final hexPos = Offset(localPos.dx - originX, localPos.dy - originY);
          final tapped = pixelToHex(hexPos, cellSize);
          // Only toggle if within our display range
          if (tapped.q.abs() <= range + 1 &&
              tapped.r.abs() <= range + 1 &&
              (tapped.q + tapped.r).abs() <= range + 1) {
            onCellToggled(tapped);
          }
        },
        child: CustomPaint(
          painter: _HexGridPainter(
            coordsInRange: coordsInRange,
            board: board,
            cellSize: cellSize,
            originX: originX,
            originY: originY,
          ),
        ),
      ),
    );
  }
}

class _HexGridPainter extends CustomPainter {
  final List<AxialCoord> coordsInRange;
  final BoardModel board;
  final double cellSize;
  final double originX;
  final double originY;

  const _HexGridPainter({
    required this.coordsInRange,
    required this.board,
    required this.cellSize,
    required this.originX,
    required this.originY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaintActive = Paint()..color = AppColors.cellActive;
    final fillPaintInactive = Paint()..color = AppColors.cellInactive;
    final borderPaint = Paint()
      ..color = AppColors.cellBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final coord in coordsInRange) {
      final center = hexToPixel(coord, cellSize);
      final cx = center.dx + originX;
      final cy = center.dy + originY;

      final cell = board.cells[coord];
      final isActive = cell?.isActive ?? false;

      final path = _flatHexPath(cx, cy, cellSize * 0.92);

      canvas.drawPath(path, isActive ? fillPaintActive : fillPaintInactive);
      canvas.drawPath(path, borderPaint);
    }
  }

  Path _flatHexPath(double cx, double cy, double size) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 3 * i; // flat-top: 0, 60, 120, ...
      final x = cx + size * cos(angle);
      final y = cy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_HexGridPainter oldDelegate) =>
      oldDelegate.board != board ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.originX != originX ||
      oldDelegate.originY != originY;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.cellBorder),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }
}

class _LoadBoardOption extends StatelessWidget {
  final String name;
  final String description;
  final VoidCallback onTap;

  const _LoadBoardOption({
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cellBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.grid_on_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
