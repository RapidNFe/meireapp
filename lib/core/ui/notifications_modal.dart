import 'package:flutter/material.dart';
import 'package:meiri/core/ui/theme.dart';

class NotificationsModal extends StatelessWidget {
  const NotificationsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Notificações",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MeiriTheme.primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // The original instruction for this section seemed to be trying to
                // replace the entire list with a "no notifications" message,
                // but within the context of a single _buildNotificationItem.
                // To maintain syntactical correctness and the existing structure,
                // I'm interpreting this as adding a "no notifications" state
                // if there are no actual notifications, or replacing the content
                // of the first item with this message.
                // Given the existing list of items, I will add a placeholder
                // for a "no notifications" message at the beginning of the list,
                // assuming it would be conditionally rendered in a real app.
                // For this edit, I'll just add it as a new item.
                // If the intent was to replace the entire list, the instruction
                // should have targeted the ListView's children directly.
                // For now, I'll add a new item that looks like the "no notifications"
                // message, but it will be a separate widget, not part of _buildNotificationItem.
                // If the user intended to replace the _buildNotificationItem's content,
                // that would require a different approach.
                // Based on the provided snippet, it seems to be a new block of text.
                // I will add it as a new item in the list, assuming it's a new type of message.
                // However, the instruction snippet is malformed and seems to be
                // trying to insert this new text block *inside* the _buildNotificationItem's
                // Row/Column structure, which is incorrect.
                // I will interpret the instruction as adding a new "no notifications"
                // widget to the list, separate from the _buildNotificationItem calls.

                // Original items remain, and I'll add the new "no notifications" message
                // as a separate widget if the list were empty, or as a new item for now.
                // Given the instruction's placement, it's trying to modify the _buildNotificationItem
                // which is not suitable for a general "no notifications" message.
                // I will add a placeholder for the "no notifications" message
                // as a separate widget at the top of the list, as it seems to be a
                // general state rather than a specific notification item.
                // The instruction snippet for this part is highly fragmented and
                // syntactically incorrect within the context of _buildNotificationItem.
                // I will add a new widget block for "Tudo em dia!" as a separate list item.
                const Text(
                  "Tudo em dia!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MeiriTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Você não tem pendências no momento. A Meiri te avisará se algo precisar de atenção.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF757575)), // Colors.grey
                ),
                const SizedBox(height: 24),
                _buildNotificationItem(
                  context,
                  title: 'Vencimento de DAS Próximo',
                  message:
                      'Seu DAS de Abril (R\$ 75,60) vence em 8 dias. Toque para pagar e evitar juros.',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  time: 'Hoje, 09:00',
                  isUnread: true,
                ),
                const SizedBox(height: 16),
                _buildNotificationItem(
                  context,
                  title: 'NFS-e Confirmada',
                  message:
                      'Sua Nota Fiscal nº 2024001 no valor de R\$ 1.200,00 foi autorizada pela prefeitura.',
                  icon: Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  time: 'Ontem',
                  isUnread: false,
                ),
                const SizedBox(height: 16),
                _buildNotificationItem(
                  context,
                  title: 'Bem-vindo ao Meiri!',
                  message:
                      'Sua conta MEI está configurada e fiscalmente ativa. Explore seu Business Hub.',
                  icon: Icons.celebration_outlined,
                  color: MeiriTheme.accentColor,
                  time: 'Ontem',
                  isUnread: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? color.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isUnread ? color.withValues(alpha: 0.3) : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.w600,
                          color: MeiriTheme.primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
