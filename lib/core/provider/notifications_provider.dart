import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pocketbase_service.dart';
import '../models/notification_model.dart';

final notificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) async* {
  final pb = ref.watch(pbProvider);
  final user = ref.watch(userProvider);
  
  if (user == null) {
    yield [];
    return;
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final records = await pb.collection('notificacoes').getFullList(
        filter: 'user_id = "${user.id}" && lida = false',
        sort: '-created',
      );
      return records.map((r) => NotificationModel.fromRecord(r)).toList();
    } catch (_) {
      return [];
    }
  }

  // 1. Initial Data
  yield await fetchNotifications();

  // 2. Real-time setup
  final streamController = StreamController<List<NotificationModel>>();
  
  pb.collection('notificacoes').subscribe('*', (e) async {
    final updatedList = await fetchNotifications();
    if (!streamController.isClosed) {
      streamController.add(updatedList);
    }
  });

  ref.onDispose(() {
    pb.collection('notificacoes').unsubscribe('*');
    streamController.close();
  });

  yield* streamController.stream;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
