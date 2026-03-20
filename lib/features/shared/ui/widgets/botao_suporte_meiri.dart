import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/ui/modals/support_modal.dart';

class BotaoSuporteMeiri extends ConsumerWidget {
  const BotaoSuporteMeiri({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => SupportModal.show(context, ref),
      backgroundColor: MeireTheme.primaryColor,
      elevation: 4,
      child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
    );
  }
}
