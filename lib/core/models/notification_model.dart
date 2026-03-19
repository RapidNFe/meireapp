import 'package:pocketbase/pocketbase.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'fiscal', 'faturamento', 'sistema', 'sucesso'
  final bool isRead; // Mapping to 'lida' in PB
  final String? routeAction; // Mapping to 'acao_rota' in PB
  final String userId;
  final DateTime created;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.routeAction,
    required this.userId,
    required this.created,
  });

  factory NotificationModel.fromRecord(RecordModel record) {
    return NotificationModel(
      id: record.id,
      title: record.getStringValue('titulo'),
      message: record.getStringValue('mensagem'),
      type: record.getStringValue('tipo').isEmpty ? 'sistema' : record.getStringValue('tipo'),
      isRead: record.getBoolValue('lida'), // 'lida' conforme novo padrão
      routeAction: record.getStringValue('acao_rota'),
      userId: record.getStringValue('user_id'),
      created: (DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now()).toLocal(),
    );
  }
}
