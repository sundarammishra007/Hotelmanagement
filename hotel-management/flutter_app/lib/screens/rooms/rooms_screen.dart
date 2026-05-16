import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/room_card.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().fetchRooms();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentUser?.isManager ?? false;
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search room number, type...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        // Tab bar
        TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Available'),
            Tab(text: 'Occupied'),
            Tab(text: 'Cleaning'),
          ],
        ),
        Expanded(
          child: Consumer<RoomProvider>(
            builder: (ctx, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(
                controller: _tabCtrl,
                children: [
                  _RoomsGrid(rooms: _filter(provider.rooms, null), onStatusChange: (id, s) {
                    provider.updateRoomStatus(id, s);
                  }),
                  _RoomsGrid(rooms: _filter(provider.rooms, RoomStatus.available), onStatusChange: (id, s) {
                    provider.updateRoomStatus(id, s);
                  }),
                  _RoomsGrid(rooms: _filter(provider.rooms, RoomStatus.occupied), onStatusChange: null),
                  _RoomsGrid(rooms: _filter(provider.rooms, RoomStatus.cleaning), onStatusChange: (id, s) {
                    provider.updateRoomStatus(id, s);
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<RoomModel> _filter(List<RoomModel> rooms, RoomStatus? status) {
    var list = status == null ? rooms : rooms.where((r) => r.status == status).toList();
    if (_search.isNotEmpty) {
      list = list.where((r) =>
          r.roomNumber.toLowerCase().contains(_search) ||
          r.roomTypeLabel.toLowerCase().contains(_search)).toList();
    }
    return list;
  }
}

class _RoomsGrid extends StatelessWidget {
  final List<RoomModel> rooms;
  final Function(String, String)? onStatusChange;

  const _RoomsGrid({required this.rooms, this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No rooms found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 800 ? 4 : c.maxWidth > 500 ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: onStatusChange != null ? 0.9 : 1.1,
        ),
        itemCount: rooms.length,
        itemBuilder: (_, i) => RoomCard(
          room: rooms[i],
          onStatusChange: onStatusChange == null
              ? null
              : (s) => onStatusChange!(rooms[i].id, s),
        ),
      );
    });
  }
}
