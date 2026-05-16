import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/checkin_model.dart';
import '../../models/room_model.dart';
import '../../services/checkin_service.dart';
import '../../services/room_service.dart';
import '../../widgets/status_badge.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _checkinService = CheckinService();
  final _roomService = RoomService();
  List<CheckinModel> _activeCheckins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _activeCheckins = await _checkinService.getActiveCheckins();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _checkout(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: const Text('Are you sure you want to check out this guest?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Check Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _checkinService.checkOut(id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guest checked out successfully!'), backgroundColor: Colors.green),
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
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Active Check-ins'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'New Check-in'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ActiveCheckinsTab(
                loading: _loading,
                checkins: _activeCheckins,
                onCheckout: _checkout,
                onRefresh: _load,
              ),
              _NewCheckinForm(onSuccess: () {
                _load();
                _tabCtrl.animateTo(0);
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveCheckinsTab extends StatelessWidget {
  final bool loading;
  final List<CheckinModel> checkins;
  final Function(String) onCheckout;
  final VoidCallback onRefresh;

  const _ActiveCheckinsTab({
    required this.loading,
    required this.checkins,
    required this.onCheckout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (checkins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hotel_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No active check-ins', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: checkins.length,
        itemBuilder: (_, i) {
          final c = checkins[i];
          final fmt = DateFormat('dd MMM yyyy');
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              (c.guestName ?? 'G')[0].toUpperCase(),
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.guestName ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(c.guestPhone ?? '',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      StatusBadge(status: c.status.name),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      _InfoChip(Icons.meeting_room, 'Room ${c.roomNumber ?? ''}'),
                      const SizedBox(width: 12),
                      _InfoChip(Icons.people, '${c.adults}A + ${c.children}C'),
                      const SizedBox(width: 12),
                      _InfoChip(Icons.nights_stay, '${c.nights} nights'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(Icons.login, 'In: ${fmt.format(c.checkInDate)}'),
                      const SizedBox(width: 12),
                      if (c.checkOutDate != null)
                        _InfoChip(Icons.logout, 'Out: ${fmt.format(c.checkOutDate!)}'),
                    ],
                  ),
                  if (c.pricePerNight != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Est. Charges: ₹${(c.nights * c.pricePerNight!).toStringAsFixed(0)} + GST',
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onCheckout(c.id),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      icon: const Icon(Icons.logout),
                      label: const Text('Check Out'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _NewCheckinForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _NewCheckinForm({required this.onSuccess});
  @override
  State<_NewCheckinForm> createState() => _NewCheckinFormState();
}

class _NewCheckinFormState extends State<_NewCheckinForm> {
  final _formKey = GlobalKey<FormState>();
  final _checkinService = CheckinService();
  final _roomService = RoomService();
  List<RoomModel> _availableRooms = [];
  String? _selectedRoomId;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));
  int _adults = 1, _children = 0;
  final _requestsCtrl = TextEditingController();
  String _idProofType = 'aadhar';
  final _idProofNumCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      _availableRooms = await _roomService.getRooms(status: 'available');
      setState(() {});
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _checkinService.createCheckin({
        'room_id': _selectedRoomId,
        'guest': {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'id_proof_type': _idProofType,
          'id_proof_number': _idProofNumCtrl.text.trim(),
        },
        'check_in_date': _checkInDate.toIso8601String(),
        'check_out_date': _checkOutDate.toIso8601String(),
        'adults': _adults,
        'children': _children,
        'special_requests': _requestsCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guest checked in successfully!'), backgroundColor: Colors.green),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Check-in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Room Selection', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRoomId,
                      hint: const Text('Select Available Room'),
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                      items: _availableRooms.map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text('Room ${r.roomNumber} - ${r.roomTypeLabel} (₹${r.pricePerNight.toStringAsFixed(0)}/night)'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedRoomId = v),
                      validator: (v) => v == null ? 'Please select a room' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Guest Details', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Phone is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _idProofType,
                      decoration: const InputDecoration(
                        labelText: 'ID Proof Type',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'aadhar', child: Text('Aadhar Card')),
                        DropdownMenuItem(value: 'passport', child: Text('Passport')),
                        DropdownMenuItem(value: 'driving_license', child: Text('Driving License')),
                        DropdownMenuItem(value: 'voter_id', child: Text('Voter ID')),
                      ],
                      onChanged: (v) => setState(() => _idProofType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idProofNumCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID Proof Number',
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stay Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _checkInDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => _checkInDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-in Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(fmt.format(_checkInDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _checkOutDate,
                                firstDate: _checkInDate.add(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => _checkOutDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-out Date',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              child: Text(fmt.format(_checkOutDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Adults: '),
                              IconButton(onPressed: () => setState(() { if (_adults > 1) _adults--; }), icon: const Icon(Icons.remove_circle_outline)),
                              Text('$_adults', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(onPressed: () => setState(() => _adults++), icon: const Icon(Icons.add_circle_outline)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Children: '),
                              IconButton(onPressed: () => setState(() { if (_children > 0) _children--; }), icon: const Icon(Icons.remove_circle_outline)),
                              Text('$_children', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(onPressed: () => setState(() => _children++), icon: const Icon(Icons.add_circle_outline)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _requestsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Special Requests (Optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login),
                          SizedBox(width: 8),
                          Text('Check In Guest', style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
