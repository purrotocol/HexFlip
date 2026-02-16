import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/widgets/app_colors.dart';
import 'package:hexflip/widgets/hex_card_widget.dart';

class HandWidget extends ConsumerWidget {
  final void Function(HexCard card) onCardSelected;
  final String? selectedCardId;

  const HandWidget({
    super.key,
    required this.onCardSelected,
    this.selectedCardId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) return const SizedBox.shrink();

    final currentPlayer = gameState.currentPlayer;
    final hand = currentPlayer.hand;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${currentPlayer.displayName}\'s Hand',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${hand.length} cards',
                style: const TextStyle(color: AppColors.accent, fontSize: 11),
              ),
              if (currentPlayer.deck.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '(${currentPlayer.deck.length} in deck)',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (hand.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Hand is empty',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hand.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final card = hand[index];
                  final isSelected = card.id == selectedCardId;
                  return HexCardWidget(
                    card: card,
                    size: 55.0,
                    isSelected: isSelected,
                    isSmall: false,
                    onTap: () => onCardSelected(card),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
