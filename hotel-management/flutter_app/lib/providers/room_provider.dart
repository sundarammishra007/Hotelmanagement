import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  final _service = RoomService();

  List<RoomModel> _rooms = [];
  RoomModel? _selectedRoom;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {};

  List<RoomModel> get rooms => _rooms;
  RoomModel? get selectedRoom => _selectedRoom;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;

  List<RoomModel> get availableRooms =>
      _rooms.where((r) => r.status == RoomStatus.available).toList();

  void _setLoading(bool val) { _isLoading = val; notifyListeners(); }

  Future<void> fetchRooms({String? status, String? roomType, int? floor}) async {
    try {
      _setLoading(true);
      _error = null;
      _rooms = await _service.getRooms(status: status, roomType: roomType, floor: floor);
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
    }
  }

  Future<void> fetchRoomStats() async {
    try {
      _stats = await _service.getRoomStats();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createRoom(Map<String, dynamic> data) async {
    try {
      final room = await _service.createRoom(data);
      _rooms.add(room);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRoomStatus(String id, String status) async {
    try {
      final updated = await _service.updateRoomStatus(id, status);
      final idx = _rooms.indexWhere((r) => r.id == id);
      if (idx != -1) _rooms[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void selectRoom(RoomModel? room) {
    _selectedRoom = room;
    notifyListeners();
  }
}
