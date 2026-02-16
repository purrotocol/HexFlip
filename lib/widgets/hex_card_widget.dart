import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/engine/hex_math.dart';
import 'package:hexflip/widgets/app_colors.dart';

class HexCardWidget extends StatelessWidget {
  final HexCard card;
  final double size;
  final bool isSelected;
  final bool isSmall;
  final VoidCallback? onTap;

  const HexCardWidget({
    super.key,
    required this.card,
    this.size = 60.0,
    this.isSelected = false,
    this.isSmall = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = card.owner == PlayerOwner.red
        ? AppColors.redPlayer
        : AppColors.bluePlayer;
    final borderColor = isSelected
        ? AppColors.attackHighlight
        : (card.owner == PlayerOwner.red
            ? AppColors.redPlayerLight
            : AppColors.bluePlayerLight);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size * 2,
        height: size * 2,
        child: CustomPaint(
          painter: _HexCardPainter(
            card: card,
            size: size,
            baseColor: baseColor,
            borderColor: borderColor,
            isSelected: isSelected,
            isSmall: isSmall,
          ),
        ),
      ),
    );
  }
}

class _HexCardPainter extends CustomPainter {
  final HexCard card;
  final double size;
  final Color baseColor;
  final Color borderColor;
  final bool isSelected;
  final bool isSmall;

  const _HexCardPainter({
    required this.card,
    required this.size,
    required this.baseColor,
    required this.borderColor,
    required this.isSelected,
    required this.isSmall,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    // Draw hex background
    final hexPath = _flatHexPath(cx, cy, size * 0.9);
    final fillPaint = Paint()..color = baseColor;
    canvas.drawPath(hexPath, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5;
    canvas.drawPath(hexPath, borderPaint);

    if (isSmall) return;

    // Draw 6 side symbols + numbers
    for (int i = 0; i < 6; i++) {
      final side = card.sides[i];
      final rotation = sideRotationRadians(i);
      // Position near the edge of the hex, ~60% of size from center
      final dist = size * 0.58;
      final symbolX = cx + dist * cos(rotation);
      final symbolY = cy + dist * sin(rotation);

      // Draw shape symbol
      final symbolSize = size * 0.16;
      _drawShape(canvas, side.shape, Offset(symbolX, symbolY - symbolSize * 0.6),
          symbolSize, side.shapeColor);

      // Draw number
      final numberPainter = TextPainter(
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
      numberPainter.paint(
        canvas,
        Offset(
          symbolX - numberPainter.width / 2,
          symbolY + symbolSize * 0.2,
        ),
      );
    }
  }

  void _drawShape(Canvas canvas, SymbolShape shape, Offset center, double size, Color color) {
    final paint = Paint()..color = color;

    switch (shape) {
      case SymbolShape.circle:
        canvas.drawCircle(center, size * 0.6, paint);
        break;

      case SymbolShape.square:
        final half = size * 0.55;
        canvas.drawRect(
          Rect.fromCenter(center: center, width: half * 2, height: half * 2),
          paint,
        );
        break;

      case SymbolShape.triangle:
        final path = Path();
        final h = size * 1.0;
        path.moveTo(center.dx, center.dy - h * 0.6);
        path.lineTo(center.dx - h * 0.55, center.dy + h * 0.4);
        path.lineTo(center.dx + h * 0.55, center.dy + h * 0.4);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case SymbolShape.star:
        final path = _starPath(center, size * 0.7, size * 0.3, 5);
        canvas.drawPath(path, paint);
        break;

      case SymbolShape.diamond:
        final path = Path();
        final r = size * 0.65;
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
  bool shouldRepaint(_HexCardPainter oldDelegate) =>
      oldDelegate.card.id != card.id ||
      oldDelegate.card.owner != card.owner ||
      oldDelegate.isSelected != isSelected ||
      oldDelegate.baseColor != baseColor;
}
