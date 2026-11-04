import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Opens [child] as the white rounded sheet from the design.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    builder: (_) => AppBottomSheet(child: child),
  );
}

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lavenderStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
