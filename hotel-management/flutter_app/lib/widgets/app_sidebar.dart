import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class NavItem {
  final IconData icon;
  final String label;
  final int index;
  const NavItem(this.icon, this.label, this.index);
}

const navItems = [
  NavItem(Icons.dashboard_outlined, 'Dashboard', 0),
  NavItem(Icons.meeting_room_outlined, 'Rooms', 1),
  NavItem(Icons.login_outlined, 'Check-in', 2),
  NavItem(Icons.people_outline, 'Guests', 3),
  NavItem(Icons.receipt_long_outlined, 'Invoices', 4),
  NavItem(Icons.badge_outlined, 'Staff', 5),
];

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    if (isWide) {
      return _DesktopSidebar(
          selectedIndex: selectedIndex, onItemSelected: onItemSelected);
    }
    return const SizedBox.shrink(); // handled by Drawer
  }

  static Drawer buildDrawer(BuildContext context, int selectedIndex,
      Function(int) onItemSelected) {
    return Drawer(
      child: _SidebarContent(
          selectedIndex: selectedIndex, onItemSelected: onItemSelected),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const _DesktopSidebar(
      {required this.selectedIndex, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: AppTheme.primaryColor,
      child: _SidebarContent(
          selectedIndex: selectedIndex, onItemSelected: onItemSelected),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const _SidebarContent(
      {required this.selectedIndex, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, Color(0xFF2D5F8F)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hotel HMS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Management System',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: navItems
                .map((item) => _NavTile(
                      item: item,
                      isSelected: selectedIndex == item.index,
                      onTap: () {
                        onItemSelected(item.index);
                        if (Scaffold.of(context).isDrawerOpen) {
                          Navigator.of(context).pop();
                        }
                      },
                    ))
                .toList(),
          ),
        ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentColor,
                    child: Text(user.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        Text(user.role.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon,
                    color: isSelected ? Colors.white : Colors.white60, size: 20),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                        color: AppTheme.accentColor, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
