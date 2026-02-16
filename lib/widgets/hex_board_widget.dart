import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/engine/hex_math.dart';
import 'package:hexflip/widgets/app_colors.dart';

class HexBoardWidget extends ConsumerWidget {
  final double cellSize;
  final AxialCoord? selectedTarget;
  final void Function(AxialCoord coord) onCellTapped;

  const HexBoardWidget({
    super.key,
    this.cellSize = 44.0,
    this.selectedTarget,
    required this.onCellTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Center(
        child: Text('No active game', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final board = gameState.board;
    final flipCoords = gameState.pendingFlipEvents.map((e) => e.cellCoord).toSet();

    // Calculate bounds for all active cells
    final activeCells = board.cells.values.where((c) => c.isActive).toList();
    if (activeCells.isEmpty) {
      return const Center(
        child: Text('Empty board', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final cell in activeCells) {
      final offset = hexToPixel(cell.coord, cellSize);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(40),
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: GestureDetector(
                onTapDown: (details) {
                  final localPos = details.localPosition;
                  final hexPos = Offset(localPos.dx - originX, localPos.dy - originY);
                  final tapped = pixelToHex(hexPos, cellSize);
                  final cell = board.cells[tapped];
                  if (cell != null && cell.isActive) {
                    onCellTapped(tapped);
                  }
                },
                child: CustomPaint(
                  painter: _BoardPainter(
                    board: board,
                    cellSize: cellSize,
                    originX: originX,
                    originY: originY,
                    flipCoords: flipCoords,
                    selectedTarget: selectedTarget,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final BoardModel board;
  final double cellSize;
  final double originX;
  final double originY;
  final Set<AxialCoord> flipCoords;
  final AxialCoord? selectedTarget;

  const _BoardPainter({
    required this.board,
    required this.cellSize,
    required this.originX,
    required this.originY,
    required this.flipCoords,
    this.selectedTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in board.cells.values) {
      if (!cell.isActive) continue;

      final center = hexToPixel(cell.coord, cellSize);
      final cx = center.dx + originX;
      final cy = center.dy + originY;

      _drawCell(canvas, cell, cx, cy);
    }
  }

  void _drawCell(Canvas canvas, HexCell cell, double cx, double cy) {
    final innerR = cellSize * 0.9;
    final path = _flatHexPath(cx, cy, innerR);

    // Fill color based on occupancy
    Color fillColor;
    if (cell.card != null) {
      fillColor = cell.card!.owner == PlayerOwner.red
          ? AppColors.redPlayer
          : AppColors.bluePlayer;
    } else {
      fillColor = AppColors.cellActive;
    }

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(path, fillPaint);

    // Border
    Color borderColor = AppColors.cellBorder;
    double borderWidth = 1.5;

    if (cell.coord == selectedTarget) {
      borderColor = AppColors.attackHighlight;
      borderWidth = 3.0;
    } else if (flipCoords.contains(cell.coord)) {
      borderColor = AppColors.flipHighlight;
      borderWidth = 3.0;
    } else if (cell.card != null) {
      borderColor = cell.card!.owner == PlayerOwner.red
          ? AppColors.redPlayerLight
          : AppColors.bluePlayerLight;
      borderWidth = 2.0;
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, borderPaint);

    // Draw card content if occupied
    if (cell.card != null) {
      _drawCardOnCell(canvas, cell.card!, cx, cy);
    }

    // Draw flip highlight indicator
    if (flipCoords.contains(cell.coord)) {
      final glowPaint = Paint()
        ..color = AppColors.flipHighlight.withAlpha(60)
        ..style = PaintingStyle.fill;
      canvas.drawPath(_flatHexPath(cx, cy, innerR * 0.85), glowPaint);
    }
  }

  void _drawCardOnCell(Canvas canvas, HexCard card, double cx, double cy) {
    // Draw 6 side indicators around the hex
    for (int i = 0; i < 6; i++) {
      final side = card.sides[i];
      final rotation = sideRotationRadians(i);
      final dist = cellSize * 0.58;
      final sx = cx + dist * cos(rotation);
      final sy = cy + dist * sin(rotation);
      final symbolSize = cellSize * 0.13;

      _drawShape(canvas, side.shape, Offset(sx, sy), symbolSize, side.shapeColor);

      // Number label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${side.number}',
          style: TextStyle(
            color: side.numberColor,
            fontSize: symbolSize * 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(sx - textPainter.width / 2, sy + symbolSize * 0.5),
      );
    }

    // Center ownership indicator
    final ownerPaint = Paint()
      ..color = (card.owner == PlayerOwner.red
              ? AppColors.redPlayerLight
              : AppColors.bluePlayerLight)
          .withAlpha(200);
    canvas.drawCircle(Offset(cx, cy), cellSize * 0.15, ownerPaint);
  }

  void _drawShape(Canvas canvas, SymbolShape shape, Offset center, double size, Color color) {
    final paint = Paint()..color = color;

    switch (shape) {
      case SymbolShape.circle:
        canvas.drawCircle(center, size * 0.7, paint);
        break;

      case SymbolShape.square:
        final half = size * 0.65;
        canvas.drawRect(
          Rect.fromCenter(center: center, width: half * 2, height: half * 2),
          paint,
        );
        break;

      case SymbolShape.triangle:
        final path = Path();
        final h = size * 1.1;
        path.moveTo(center.dx, center.dy - h * 0.6);
        path.lineTo(center.dx - h * 0.55, center.dy + h * 0.4);
        path.lineTo(center.dx + h * 0.55, center.dy + h * 0.4);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case SymbolShape.star:
        final path = _starPath(center, size * 0.8, size * 0.35, 5);
        canvas.drawPath(path, paint);
        break;

      case SymbolShape.diamond:
        final path = Path();
        final r = size * 0.75;
        path.moveTo(center.dx, center.dy - r);
        path.lineTo(center.dx + r * 0.65, center.dy);
        path.lineTo(center.dx, center.dy + r);
        path.lineTo(center.dx - r * 0.65, center.dy);
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  Path _starPath(Offset center, double outerR, double innerR, int points) {
    final path = Path();
    final totalPoints = points * 2;
    for (int i = 0; i < totalPoints; i++) {
      final angle = (pi / points) * i - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _flatHexPath(double cx, double cy, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 3 * i;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
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
  bool shouldRepaint(_BoardPainter oldDelegate) =>
      oldDelegate.board != board ||
      oldDelegate.flipCoords != flipCoords ||
      oldDelegate.selectedTarget != selectedTarget;
}
