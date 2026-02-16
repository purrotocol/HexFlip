import 'package:flutter/material.dart';
import 'package:hexflip/screens/setup_screen.dart';
import 'package:hexflip/screens/card_editor_screen.dart';
import 'package:hexflip/screens/board_editor_screen.dart';
import 'package:hexflip/screens/rules_editor_screen.dart';
import 'package:hexflip/widgets/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'HexFlip',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hex Card Game Playtesting',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 64),
            _NavButton(
              label: 'New Game',
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SetupScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _NavButton(
              label: 'Card Editor',
              icon: Icons.style_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardEditorScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _NavButton(
              label: 'Board Editor',
              icon: Icons.grid_on_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BoardEditorScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _NavButton(
              label: 'Rules Editor',
              icon: Icons.tune_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RulesEditorScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 17, letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceAlt,
          foregroundColor: AppColors.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cellBorder),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
