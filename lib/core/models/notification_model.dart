import 'package:pocketbase/pocketbase.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'success', 'error'
  final bool isRead;
  final DateTime created;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.created,
  });

  factory NotificationModel.fromRecord(RecordModel record) {
    return NotificationModel(
      id: record.id,
      title: record.getStringValue('titulo'),
      message: record.getStringValue('mensagem'),
      type: record.getStringValue('tipo').isEmpty ? 'info' : record.getStringValue('tipo'),
      isRead: record.getBoolValue('lido'),
      created: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
    );
  }
}
