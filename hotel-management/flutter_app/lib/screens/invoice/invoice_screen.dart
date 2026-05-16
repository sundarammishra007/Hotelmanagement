import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../widgets/status_badge.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});
  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _invoiceService = InvoiceService();
  List<InvoiceModel> _invoices = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _invoices = await _invoiceService.getInvoices(paymentStatus: _statusFilter); }
    catch (_) {}
    setState(() => _loading = false);
  }

  void _showInvoiceDetail(InvoiceModel inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _InvoiceDetailSheet(invoice: inv, invoiceService: _invoiceService, onRefresh: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [null, 'pending', 'partial', 'paid', 'refunded'].map((s) {
              final isSelected = _statusFilter == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s == null ? 'All' : s[0].toUpperCase() + s.substring(1)),
                  selected: isSelected,
                  onSelected: (_) { setState(() => _statusFilter = s); _load(); },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                  checkmarkColor: AppTheme.primaryColor,
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _invoices.isEmpty
                  ? const Center(child: Text('No invoices found', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _invoices.length,
                        itemBuilder: (_, i) {
                          final inv = _invoices[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => _showInvoiceDetail(inv),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(inv.invoiceNumber,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(inv.guestName ?? '',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          Text('Room ${inv.roomNumber ?? ''}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(currFmt.format(inv.totalAmount),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        StatusBadge(status: inv.paymentStatus.name),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _InvoiceDetailSheet extends StatefulWidget {
  final InvoiceModel invoice;
  final InvoiceService invoiceService;
  final VoidCallback onRefresh;
  const _InvoiceDetailSheet({required this.invoice, required this.invoiceService, required this.onRefresh});
  @override
  State<_InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<_InvoiceDetailSheet> {
  InvoiceModel? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      _detail = await widget.invoiceService.getInvoiceById(widget.invoice.id);
    } catch (_) { _detail = widget.invoice; }
    setState(() => _loading = false);
  }

  Future<void> _downloadPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading PDF...'), duration: Duration(seconds: 1)),
      );
      await widget.invoiceService.downloadInvoicePDF(widget.invoice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addPayment() async {
    String method = 'cash';
    final amtCtrl = TextEditingController();
    final txCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (ctx, ss) => DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
              ],
              onChanged: (v) => ss(() => method = v!),
            )),
            const SizedBox(height: 12),
            TextField(
              controller: txCtrl,
              decoration: const InputDecoration(labelText: 'Transaction ID (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(_, true), child: const Text('Record Payment')),
        ],
      ),
    );
    if (result != true || amtCtrl.text.isEmpty) return;
    try {
      await widget.invoiceService.addPayment(widget.invoice.id, {
        'amount': double.parse(amtCtrl.text),
        'payment_method': method,
        'transaction_id': txCtrl.text.trim(),
      });
      _loadDetail();
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _detail ?? widget.invoice;
    final currFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(inv.invoiceNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          StatusBadge(status: inv.paymentStatus.name, fontSize: 13),
                        ],
                      ),
                      if (inv.guestName != null)
                        Text(inv.guestName!, style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 24),
                      // Charges
                      _LineItem('Room Charges', currFmt.format(inv.roomCharges)),
                      _LineItem('Extra Charges', currFmt.format(inv.extraCharges)),
                      _LineItem('Discount', '- ${currFmt.format(inv.discount)}'),
                      _LineItem('Subtotal', currFmt.format(inv.subtotal)),
                      _LineItem('CGST (${inv.cgstRate}%)', currFmt.format(inv.cgstAmount)),
                      _LineItem('SGST (${inv.sgstRate}%)', currFmt.format(inv.sgstAmount)),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(currFmt.format(inv.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.accentColor)),
                        ],
                      ),
                      // Payments
                      if (inv.payments != null && inv.payments!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Payment History', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...inv.payments!.map((p) => _LineItem(
                          '${p.methodLabel} - ${DateFormat('dd MMM').format(p.paidAt ?? DateTime.now())}',
                          currFmt.format(p.amount),
                          color: Colors.green,
                        )),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _downloadPDF,
                              icon: const Icon(Icons.download),
                              label: const Text('Download PDF'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (inv.paymentStatus != PaymentStatus.paid)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addPayment,
                                icon: const Icon(Icons.payment),
                                label: const Text('Add Payment'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _LineItem(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
