import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/guest_model.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key});
  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  final _api = ApiService();
  List<dynamic> _guests = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get(
        ApiConfig.guestsEndpoint,
        queryParams: _search.isNotEmpty ? {'search': _search} : null,
      );
      _guests = data['data'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showGuestDetail(Map<String, dynamic> g) async {
    Map<String, dynamic>? detail;
    try {
      final d = await _api.get('${ApiConfig.guestsEndpoint}/${g['id']}');
      detail = d['data'] as Map<String, dynamic>;
    } catch (_) { detail = g; }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (detail!['name'] as String? ?? 'G')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(detail['name']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(detail['phone']?.toString() ?? '', style: const TextStyle(color: Colors.grey)),
                            if (detail['email'] != null) Text(detail['email'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _DetailRow(Icons.badge_outlined, 'ID Proof', '${detail['id_proof_type'] ?? 'N/A'} - ${detail['id_proof_number'] ?? ''}'),
                  _DetailRow(Icons.public, 'Nationality', detail['nationality']?.toString() ?? 'N/A'),
                  _DetailRow(Icons.home_outlined, 'Address', detail['address']?.toString() ?? 'N/A'),
                  const SizedBox(height: 16),
                  const Text('Stay History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if ((detail['checkin_history'] as List?)?.isNotEmpty == true)
                    ...(detail['checkin_history'] as List).map((c) {
                      final m = c as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.hotel, color: AppTheme.primaryColor, size: 18),
                        title: Text('Room ${m['room_number'] ?? ''}'),
                        subtitle: Text('${m['check_in_date'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(m['check_in_date'])) : ''}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: m['status'] == 'active' ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(m['status']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                        ),
                      );
                    })
                  else
                    const Text('No previous stays', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name, phone, email...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) {
              _search = v;
              if (v.length >= 3 || v.isEmpty) _load();
            },
            onSubmitted: (_) => _load(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _guests.isEmpty
                  ? const Center(child: Text('No guests found', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _guests.length,
                        itemBuilder: (_, i) {
                          final g = _guests[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => _showGuestDetail(g),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  (g['name'] as String? ?? 'G')[0].toUpperCase(),
                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(g['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g['phone']?.toString() ?? ''),
                                  if (g['nationality'] != null)
                                    Text(g['nationality'].toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
