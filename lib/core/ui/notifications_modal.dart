import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/provider/notifications_provider.dart';
import 'package:meire/core/models/notification_model.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:intl/intl.dart';

class NotificationsModal extends ConsumerWidget {
  const NotificationsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsModal(),
    );
  }

  void _markAllAsRead(BuildContext context, WidgetRef ref) async {
    final notifications = ref.read(notificationsProvider).valueOrNull ?? [];
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    final pbInstance = ref.read(pbProvider);
    try {
      // Paraleliza as atualizações para ser mais rápido
      await Future.wait(unread.map(
        (n) => pbInstance.collection('notificacoes').update(n.id, body: {'lida': true}),
      ));
      
      // Força a atualização do provider (caso o stream demore)
      ref.invalidate(notificationsProvider);
    } catch (e) {
      debugPrint('Erro ao marcar todas como lidas: $e');
    }
  }

  void _markAsRead(BuildContext context, WidgetRef ref, NotificationModel notification) async {
    if (!notification.isRead) {
      final pbInstance = ref.read(pbProvider);
      try {
        await pbInstance.collection('notificacoes').update(
          notification.id,
          body: {'lida': true}, // 'lida' conforme novo padrão
        );
        ref.invalidate(notificationsProvider);
      } catch (e) {
        debugPrint('Erro ao marcar como lida: $e');
      }
    }

    // Navegação Inteligente (Ação de Rota)
    if (context.mounted && notification.routeAction != null && notification.routeAction!.isNotEmpty) {
      Navigator.pop(context); // Fecha o modal antes de navegar
      Navigator.pushNamed(context, notification.routeAction!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

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
                  "Avisos da Meire",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MeireTheme.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _markAllAsRead(context, ref),
                      child: const Text("Limpar", style: TextStyle(color: MeireTheme.accentColor, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return InkWell(
                      onTap: () => _markAsRead(context, ref, n),
                      borderRadius: BorderRadius.circular(12),
                      child: _buildNotificationItem(
                        context,
                        title: n.title,
                        message: n.message,
                        icon: _getIconForType(n.type),
                        color: _getColorForType(n.type),
                        time: _formatCreated(n.created),
                        isUnread: !n.isRead,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text("Erro ao carregar avisos: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 64, color: MeireTheme.primaryColor.withValues(alpha: 0.1)),
        const SizedBox(height: 24),
        const Text(
          "Tudo em dia!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MeireTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Você não tem avisos pendentes. A Meire te notificará se houver novidades fiscais.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF757575)),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'fiscal': return Icons.account_balance_outlined;
      case 'faturamento': return Icons.trending_up_rounded;
      case 'sucesso': return Icons.check_circle_outline_rounded;
      case 'sistema': return Icons.settings_suggest_outlined;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'fiscal': return Colors.red.shade700;
      case 'faturamento': return MeireTheme.accentColor;
      case 'sucesso': return Colors.green.shade700;
      case 'sistema': return Colors.blue.shade700;
      default: return MeireTheme.primaryColor;
    }
  }

  String _formatCreated(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return "Hoje, ${DateFormat('HH:mm').format(dt)}";
    }
    return DateFormat('dd/MM, HH:mm').format(dt);
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
            color: isUnread ? color.withValues(alpha: 0.3) : Colors.grey.shade200),
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
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: MeireTheme.primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
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
