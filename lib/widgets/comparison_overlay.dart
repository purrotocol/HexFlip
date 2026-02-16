import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/engine/adjacency_resolver.dart';
import 'package:hexflip/widgets/app_colors.dart';

class ComparisonOverlay extends StatelessWidget {
  final List<AdjacencyComparison> comparisons;
  final VoidCallback onDismiss;

  const ComparisonOverlay({
    super.key,
    required this.comparisons,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withAlpha(178),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping inside
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cellBorder, width: 1.5),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.compare_arrows_rounded, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Attack Results',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${comparisons.where((c) => c.flipped).length} flipped',
                          style: const TextStyle(color: AppColors.flipHighlight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Comparison rows
                  Expanded(
                    child: comparisons.isEmpty
                        ? const Center(
                            child: Text(
                              'No adjacent opponents',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: comparisons.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: AppColors.cellBorder, height: 12),
                            itemBuilder: (context, index) {
                              return _ComparisonRow(comparison: comparisons[index]);
                            },
                          ),
                  ),
                  // Dismiss button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onDismiss,
                        child: const Text('Continue', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final AdjacencyComparison comparison;

  const _ComparisonRow({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final resultColor = comparison.flipped
        ? AppColors.flipHighlight
        : (comparison.eligible ? AppColors.textMuted : AppColors.textMuted);

    final resultLabel = comparison.flipped
        ? 'FLIPPED'
        : (comparison.eligible ? 'No Flip' : 'Ineligible');

    final resultIcon = comparison.flipped
        ? Icons.rotate_right_rounded
        : (comparison.eligible ? Icons.close_rounded : Icons.block_rounded);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: comparison.flipped
              ? AppColors.flipHighlight.withAlpha(128)
              : AppColors.cellBorder,
        ),
      ),
      child: Row(
        children: [
          // Attacker side
          Expanded(
            child: _SideInfo(
              side: comparison.attackerSide,
              label: 'Attacker',
              sideIndex: comparison.attackerSideIndex,
              isAttacker: true,
            ),
          ),
          const SizedBox(width: 8),
          // VS / result indicator
          Column(
            children: [
              Icon(resultIcon, color: resultColor, size: 20),
              const SizedBox(height: 4),
              Text(
                resultLabel,
                style: TextStyle(
                  color: resultColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Defender side
          Expanded(
            child: _SideInfo(
              side: comparison.defenderSide,
              label: 'Defender',
              sideIndex: comparison.defenderSideIndex,
              isAttacker: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideInfo extends StatelessWidget {
  final CardSide side;
  final String label;
  final int sideIndex;
  final bool isAttacker;

  const _SideInfo({
    required this.side,
    required this.label,
    required this.sideIndex,
    required this.isAttacker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isAttacker
            ? AppColors.redPlayer.withAlpha(80)
            : AppColors.bluePlayer.withAlpha(80),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isAttacker ? AppColors.redPlayerLight : AppColors.bluePlayerLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              CustomPaint(
                size: const Size(16, 16),
                painter: _ShapeIconPainter(shape: side.shape, color: side.shapeColor),
              ),
              const SizedBox(width: 4),
              Text(
                _shapeName(side.shape),
                style: const TextStyle(color: AppColors.text, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Number: ${side.number}',
            style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'Side ${sideIndex + 1}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _shapeName(SymbolShape shape) {
    switch (shape) {
      case SymbolShape.circle:
        return 'Circle';
      case SymbolShape.square:
        return 'Square';
      case SymbolShape.triangle:
        return 'Triangle';
      case SymbolShape.star:
        return 'Star';
      case SymbolShape.diamond:
        return 'Diamond';
    }
  }
}

class _ShapeIconPainter extends CustomPainter {
  final SymbolShape shape;
  final Color color;

  const _ShapeIconPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.45;

    switch (shape) {
      case SymbolShape.circle:
        canvas.drawCircle(Offset(cx, cy), r, paint);
        break;

      case SymbolShape.square:
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 1.8, height: r * 1.8),
          paint,
        );
        break;

      case SymbolShape.triangle:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx - r, cy + r * 0.6)
          ..lineTo(cx + r, cy + r * 0.6)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case SymbolShape.star:
        final path = _starPath(Offset(cx, cy), r, r * 0.4, 5);
        canvas.drawPath(path, paint);
        break;

      case SymbolShape.diamond:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.65, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.65, cy)
          ..close();
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

  @override
  bool shouldRepaint(_ShapeIconPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}
