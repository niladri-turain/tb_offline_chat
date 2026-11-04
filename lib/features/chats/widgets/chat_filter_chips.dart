import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum ChatFilter {
  all('All'),
  unread('Unread'),
  inRange('In range');

  const ChatFilter(this.label);
  final String label;
}

class ChatFilterChips extends StatelessWidget {
  const ChatFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ChatFilter selected;
  final ValueChanged<ChatFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final f in ChatFilter.values) ...[
          _Chip(
            label: f.label,
            active: f == selected,
            onTap: () => onSelected(f),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.ink : AppColors.lavender,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: active ? AppColors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
