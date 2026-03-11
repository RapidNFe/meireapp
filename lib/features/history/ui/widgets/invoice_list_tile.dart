import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/history/models/invoice_model.dart';

class InvoiceListTile extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  const InvoiceListTile({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final DateFormat dateFormat = DateFormat('dd MMM yyyy', 'pt_BR');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MeireTheme.iceGray),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MeireTheme.iceGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long,
                  color: MeireTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MeireTheme.primaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(invoice.issueDate),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: invoice.status == 'Emitida'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          invoice.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: invoice.status == 'Emitida'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(invoice.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: MeireTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: MeireTheme.iceGray),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
