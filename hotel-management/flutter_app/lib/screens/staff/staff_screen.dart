import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/staff_model.dart';
import '../../services/staff_service.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _staffService = StaffService();
  List<StaffModel> _staff = [];
  bool _loading = true;
  String? _roleFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _staff = await _staffService.getStaff(); }
    catch (_) {}
    setState(() => _loading = false);
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final empIdCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'receptionist';
    String shift = 'morning';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: const Text('Add Staff Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 12),
                TextField(controller: empIdCtrl, decoration: const InputDecoration(labelText: 'Employee ID *', prefixIcon: Icon(Icons.badge_outlined))),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'receptionist', child: Text('Receptionist')),
                    DropdownMenuItem(value: 'housekeeping', child: Text('Housekeeping')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  ],
                  onChanged: (v) => ss(() => role = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: shift,
                  decoration: const InputDecoration(labelText: 'Shift'),
                  items: const [
                    DropdownMenuItem(value: 'morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'evening', child: Text('Evening')),
                    DropdownMenuItem(value: 'night', child: Text('Night')),
                  ],
                  onChanged: (v) => ss(() => shift = v!),
                ),
                const SizedBox(height: 8),
                const Text('Default password: staff123', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || empIdCtrl.text.isEmpty) return;
                try {
                  await _staffService.createStaff({
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'employee_id': empIdCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'role': role,
                    'shift': shift,
                  });
                  Navigator.pop(ctx);
                  _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Staff added!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Add Staff'),
            ),
          ],
        ),
      ),
    );
  }

  List<StaffModel> get _filtered =>
      _roleFilter == null ? _staff : _staff.where((s) => s.userRole == _roleFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [null, 'admin', 'manager', 'receptionist', 'housekeeping'].map((r) =>
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(r == null ? 'All' : r[0].toUpperCase() + r.substring(1)),
                    selected: _roleFilter == r,
                    onSelected: (_) { setState(() => _roleFilter = r); },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                  ),
                ),
              ).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final s = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(
                                (s.userName ?? 'S')[0].toUpperCase(),
                                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(s.userName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${s.roleLabel} • ${s.employeeId}'),
                                Text('${s.department ?? ''} • ${s.shiftLabel} shift',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                try {
                                  await _staffService.markAttendance(s.id, {'status': 'present'});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Attendance marked for ${s.userName}'), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.orange),
                                    );
                                  }
                                }
                              },
                              child: const Text('Mark\nPresent', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Staff', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
