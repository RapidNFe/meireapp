import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/ui/modals/support_modal.dart';

class BotaoSuporteMeiri extends ConsumerWidget {
  const BotaoSuporteMeiri({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => SupportModal.show(context, ref),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle highlight glow
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MeireTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 8,
                )
              ],
            ),
          ),
          Hero(
            tag: 'meiri_assistant_hero',
            child: Image.asset(
              'assets/images/meiribb.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
