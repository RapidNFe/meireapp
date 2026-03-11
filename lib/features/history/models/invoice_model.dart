class InvoiceModel {
  final String id;
  final String clientName;
  final String clientCnpj;
  final double amount;
  final DateTime issueDate;
  final String status;

  InvoiceModel({
    required this.id,
    required this.clientName,
    required this.clientCnpj,
    required this.amount,
    required this.issueDate,
    required this.status,
  });
}
