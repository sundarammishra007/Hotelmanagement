import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/stat_card.dart';
import '../auth/login_screen.dart';
import '../checkin/checkin_screen.dart';
import '../guests/guests_screen.dart';
import '../invoice/invoice_screen.dart';
import '../rooms/rooms_screen.dart';
import '../staff/staff_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    _DashboardBody(),
    RoomsScreen(),
    CheckinScreen(),
    GuestsScreen(),
    InvoiceScreen(),
    StaffScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final titles = ['Dashboard', 'Rooms', 'Check-in / Check-out', 'Guests', 'Invoices', 'Staff'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        leading: isWide
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardProvider>().refresh(),
            tooltip: 'Refresh',
          ),
          Consumer<AuthProvider>(
            builder: (ctx, auth, _) => PopupMenuButton(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.accentColor,
                  child: Text(
                    (auth.currentUser?.name ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(auth.currentUser?.name ?? ''),
                    subtitle: Text(auth.currentUser?.role ?? ''),
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: () async {
                    await auth.logout();
                    if (ctx.mounted) {
                      Navigator.of(ctx).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                  child: const ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Logout', style: TextStyle(color: Colors.red)),
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWide
          ? null
          : AppSidebar.buildDrawer(context, _selectedIndex, (i) {
              setState(() => _selectedIndex = i);
            }),
      body: Row(
        children: [
          if (isWide)
            AppSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (i) => setState(() => _selectedIndex = i),
            ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.stats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = provider.stats;
        final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.lastUpdated != null)
                  Text(
                    'Last updated: ${DateFormat('hh:mm a').format(provider.lastUpdated!)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                const SizedBox(height: 16),
                // Stat Cards Grid
                LayoutBuilder(builder: (ctx, c) {
                  final cols = c.maxWidth > 800 ? 4 : c.maxWidth > 500 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cols == 1 ? 3.5 : 2.2,
                    children: [
                      StatCard(
                        title: 'Active Guests',
                        value: '${stats['activeGuests'] ?? 0}',
                        icon: Icons.person,
                        color: const Color(0xFF2196F3),
                        subtitle: 'Currently staying',
                      ),
                      StatCard(
                        title: 'Available Rooms',
                        value: '${stats['availableRooms'] ?? 0}',
                        icon: Icons.meeting_room,
                        color: const Color(0xFF4CAF50),
                        subtitle: 'Ready to book',
                      ),
                      StatCard(
                        title: 'Occupied Rooms',
                        value: '${stats['occupiedRooms'] ?? 0}',
                        icon: Icons.hotel,
                        color: const Color(0xFFF44336),
                        subtitle: '${stats['occupancyRate'] ?? 0}% occupancy',
                      ),
                      StatCard(
                        title: 'Revenue Today',
                        value: currencyFmt.format(stats['revenueToday'] ?? 0),
                        icon: Icons.currency_rupee,
                        color: const Color(0xFF9C27B0),
                        subtitle: 'This month: ${currencyFmt.format(stats['revenueThisMonth'] ?? 0)}',
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                // Second row
                LayoutBuilder(builder: (ctx, c) {
                  final cols = c.maxWidth > 800 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cols == 1 ? 3.5 : 2.2,
                    children: [
                      StatCard(
                        title: 'Checked In Today',
                        value: '${stats['checkedInToday'] ?? 0}',
                        icon: Icons.login,
                        color: const Color(0xFF00BCD4),
                        subtitle: 'New arrivals',
                      ),
                      StatCard(
                        title: 'Checked Out Today',
                        value: '${stats['checkedOutToday'] ?? 0}',
                        icon: Icons.logout,
                        color: const Color(0xFFFF9800),
                        subtitle: 'Departures',
                      ),
                      StatCard(
                        title: 'Cleaning Rooms',
                        value: '${stats['cleaningRooms'] ?? 0}',
                        icon: Icons.cleaning_services,
                        color: const Color(0xFF607D8B),
                        subtitle: 'Being prepared',
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),
                // Revenue Chart + Recent Checkins
                LayoutBuilder(builder: (ctx, c) {
                  if (c.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _RevenueCard(stats: stats)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _RecentCheckinsCard(stats: stats)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _RevenueCard(stats: stats),
                      const SizedBox(height: 16),
                      _RecentCheckinsCard(stats: stats),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _RevenueCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Monthly comparison', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100000,
                  barGroups: [
                    _bar(0, 45000, AppTheme.primaryColor),
                    _bar(1, 62000, AppTheme.primaryColor),
                    _bar(2, 38000, AppTheme.primaryColor),
                    _bar(3, 71000, AppTheme.primaryColor),
                    _bar(4, 55000, AppTheme.primaryColor),
                    _bar(5, (stats['revenueThisMonth'] as num?)?.toDouble() ?? 0, AppTheme.accentColor),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          final i = val.toInt();
                          return i < months.length
                              ? Text(months[i], style: const TextStyle(fontSize: 10))
                              : const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    horizontalInterval: 25000,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RevStat('Today', '₹${((stats['revenueToday'] as num?) ?? 0).toStringAsFixed(0)}', AppTheme.accentColor),
                _RevStat('Month', '₹${((stats['revenueThisMonth'] as num?) ?? 0).toStringAsFixed(0)}', AppTheme.primaryColor),
                _RevStat('Year', '₹${((stats['revenueThisYear'] as num?) ?? 0).toStringAsFixed(0)}', const Color(0xFF4CAF50)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: color, width: 18, borderRadius: BorderRadius.circular(4))],
    );
  }
}

class _RevStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RevStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _RecentCheckinsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _RecentCheckinsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final checkins = (stats['recentCheckins'] as List<dynamic>?) ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Check-ins',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${checkins.length} records',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            if (checkins.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No recent check-ins', style: TextStyle(color: Colors.grey)),
              ))
            else
              ...checkins.map((c) {
                final checkIn = c as Map<String, dynamic>;
                final date = DateTime.tryParse(checkIn['check_in_date']?.toString() ?? '');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (checkIn['guest_name'] as String? ?? 'G')[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checkIn['guest_name']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              'Room ${checkIn['room_number']} • ${date != null ? DateFormat('dd MMM').format(date) : ''}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: checkIn['status'] == 'active'
                              ? const Color(0xFF2196F3).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          checkIn['status']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: checkIn['status'] == 'active'
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
