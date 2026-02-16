import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexflip/models/models.dart';
import 'package:hexflip/state/state.dart';
import 'package:hexflip/widgets/app_colors.dart';

// Preset colors for attack eligibility color selector
const List<Color> _presetColors = [
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFCC0000),
  Color(0xFF0044CC),
  Color(0xFF007700),
  Color(0xFFFFCC00),
  Color(0xFFFF8800),
  Color(0xFF880088),
  Color(0xFF00AACC),
  Color(0xFFCC0066),
  Color(0xFF888888),
  Color(0xFF884422),
];

const List<String> _presetColorNames = [
  'Black', 'White', 'Red', 'Blue', 'Green', 'Yellow',
  'Orange', 'Purple', 'Cyan', 'Pink', 'Gray', 'Brown',
];

class RulesEditorScreen extends ConsumerWidget {
  const RulesEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(gameRulesProvider);
    final notifier = ref.read(gameRulesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Rules Editor', style: TextStyle(color: AppColors.text)),
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restore_rounded, color: AppColors.textMuted),
            label: const Text('Reset', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => notifier.update(GameRules()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader('Hand & Deck'),
          const SizedBox(height: 12),
          _NumberRuleRow(
            label: 'Starting Hand Size',
            value: rules.startingHandSize,
            min: 1,
            max: 10,
            onChanged: notifier.setStartingHandSize,
          ),
          const SizedBox(height: 12),
          _NumberRuleRow(
            label: 'Cards Drawn Per Turn',
            value: rules.cardsDrawnPerTurn,
            min: 0,
            max: 5,
            onChanged: notifier.setCardsDrawnPerTurn,
          ),
          const SizedBox(height: 12),
          _NumberRuleRow(
            label: 'Hand Limit',
            value: rules.handLimit,
            min: 1,
            max: 20,
            onChanged: notifier.setHandLimit,
          ),
          const SizedBox(height: 12),
          _NumberRuleRow(
            label: 'Deck Size',
            value: rules.deckSize,
            min: 1,
            max: 40,
            onChanged: notifier.setDeckSize,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Gameplay'),
          const SizedBox(height: 12),
          _SwitchRuleRow(
            label: 'Auto Draw Enabled',
            subtitle: 'Automatically draw at start of turn',
            value: rules.autoDrawEnabled,
            onChanged: notifier.setAutoDrawEnabled,
          ),
          const SizedBox(height: 8),
          _SwitchRuleRow(
            label: 'Placement Required',
            subtitle: 'Player must place a card each turn',
            value: rules.placementRequired,
            onChanged: notifier.setPlacementRequired,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Attack Eligibility'),
          const SizedBox(height: 12),
          _AttackEligibilityEditor(
            rule: rules.attackEligibility,
            onChanged: notifier.setAttackEligibility,
          ),
          const SizedBox(height: 20),
          _SectionHeader('Comparison Rules'),
          const SizedBox(height: 12),
          _ComparisonRuleEditor(
            rule: rules.comparisonRule,
            onChanged: notifier.setComparisonRule,
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: 240,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Rules', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rules saved'),
                      backgroundColor: AppColors.surfaceAlt,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: AppColors.cellBorder),
      ],
    );
  }
}

class _NumberRuleRow extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _NumberRuleRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_NumberRuleRow> createState() => _NumberRuleRowState();
}

class _NumberRuleRowState extends State<_NumberRuleRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(_NumberRuleRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: const TextStyle(color: AppColors.text, fontSize: 14)),
                Text(
                  '${widget.min}–${widget.max}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted),
                onPressed: widget.value > widget.min
                    ? () => widget.onChanged(widget.value - 1)
                    : null,
              ),
              SizedBox(
                width: 56,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text, fontSize: 15),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cellBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) {
                      widget.onChanged(parsed.clamp(widget.min, widget.max));
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.textMuted),
                onPressed: widget.value < widget.max
                    ? () => widget.onChanged(widget.value + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRuleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _SwitchRuleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.text, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _AttackEligibilityEditor extends StatelessWidget {
  final AttackEligibilityRule rule;
  final void Function(AttackEligibilityRule) onChanged;

  const _AttackEligibilityEditor({required this.rule, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Mode:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<AttackMode>(
                  value: rule.mode,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceAlt,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  underline: Container(height: 1, color: AppColors.cellBorder),
                  items: AttackMode.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_modeName(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (m) {
                    if (m != null) {
                      onChanged(rule.copyWith(mode: m));
                    }
                  },
                ),
              ),
            ],
          ),
          if (rule.mode == AttackMode.specificShape ||
              rule.mode == AttackMode.shapeAndColor) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Required Shape:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<SymbolShape?>(
                    value: rule.requiredShape,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceAlt,
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                    underline: Container(height: 1, color: AppColors.cellBorder),
                    hint: const Text('Any', style: TextStyle(color: AppColors.textMuted)),
                    items: [
                      const DropdownMenuItem<SymbolShape?>(
                        value: null,
                        child: Text('Any', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      ...SymbolShape.values.map(
                        (s) => DropdownMenuItem<SymbolShape?>(
                          value: s,
                          child: Text(_shapeName(s)),
                        ),
                      ),
                    ],
                    onChanged: (s) {
                      onChanged(AttackEligibilityRule(
                        mode: rule.mode,
                        requiredShape: s,
                        requiredColor: rule.requiredColor,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ],
          if (rule.mode == AttackMode.specificColor ||
              rule.mode == AttackMode.shapeAndColor) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Required Color:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(width: 12),
                _InlineColorPicker(
                  selectedColor: rule.requiredColor,
                  onSelected: (c) {
                    onChanged(AttackEligibilityRule(
                      mode: rule.mode,
                      requiredShape: rule.requiredShape,
                      requiredColor: c,
                    ));
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _modeName(AttackMode mode) {
    switch (mode) {
      case AttackMode.allSides:
        return 'All Sides';
      case AttackMode.specificShape:
        return 'Specific Shape';
      case AttackMode.specificColor:
        return 'Specific Color';
      case AttackMode.shapeAndColor:
        return 'Shape + Color';
    }
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

class _InlineColorPicker extends StatelessWidget {
  final Color? selectedColor;
  final void Function(Color?) onSelected;

  const _InlineColorPicker({required this.selectedColor, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: selectedColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selectedColor != null ? AppColors.accent : AppColors.cellBorder,
                width: 2,
              ),
            ),
            child: selectedColor == null
                ? const Icon(Icons.block, size: 16, color: AppColors.textMuted)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: selectedColor != null ? () => onSelected(null) : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: const Text('Clear', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Pick Color', style: TextStyle(color: AppColors.text)),
        content: SizedBox(
          width: 240,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _presetColors.length,
            itemBuilder: (context, index) {
              final color = _presetColors[index];
              final isSelected = selectedColor?.value == color.value;
              return Tooltip(
                message: _presetColorNames[index],
                child: GestureDetector(
                  onTap: () {
                    onSelected(color);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.cellBorder,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
}

class _ComparisonRuleEditor extends StatelessWidget {
  final ComparisonRule rule;
  final void Function(ComparisonRule) onChanged;

  const _ComparisonRuleEditor({required this.rule, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cellBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _CheckboxRow(
            label: 'Require Number Greater',
            subtitle: 'Attacker number > defender number',
            value: rule.requireNumberGreater,
            onChanged: (v) => onChanged(rule.copyWith(requireNumberGreater: v)),
          ),
          _CheckboxRow(
            label: 'Allow Equal',
            subtitle: 'Attacker number >= defender number',
            value: rule.allowEqual,
            onChanged: (v) => onChanged(rule.copyWith(allowEqual: v)),
          ),
          _CheckboxRow(
            label: 'Require Shape Match',
            subtitle: 'Both cards must share the same shape',
            value: rule.requireShapeMatch,
            onChanged: (v) => onChanged(rule.copyWith(requireShapeMatch: v)),
          ),
          _CheckboxRow(
            label: 'Require Color Match',
            subtitle: 'Both cards must share the same shape color',
            value: rule.requireColorMatch,
            onChanged: (v) => onChanged(rule.copyWith(requireColorMatch: v)),
          ),
          _CheckboxRow(
            label: 'Require Both Shape + Color',
            subtitle: 'Both shape and color must match',
            value: rule.requireBothShapeAndColor,
            onChanged: (v) => onChanged(rule.copyWith(requireBothShapeAndColor: v)),
          ),
        ],
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _CheckboxRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: AppColors.accent,
      checkColor: AppColors.background,
      controlAffinity: ListTileControlAffinity.trailing,
      dense: true,
    );
  }
}
