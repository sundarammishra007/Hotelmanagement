import 'api_service.dart';
import '../config/api_config.dart';
import '../models/room_model.dart';

class RoomService {
  final _api = ApiService();

  Future<List<RoomModel>> getRooms({String? status, String? roomType, int? floor}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (roomType != null) params['room_type'] = roomType;
    if (floor != null) params['floor'] = floor.toString();
    final data = await _api.get(ApiConfig.roomsEndpoint, queryParams: params);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((j) => RoomModel.fromJson(j)).toList();
  }

  Future<RoomModel> getRoomById(String id) async {
    final data = await _api.get('${ApiConfig.roomsEndpoint}/$id');
    return RoomModel.fromJson(data['data']);
  }

  Future<RoomModel> createRoom(Map<String, dynamic> body) async {
    final data = await _api.post(ApiConfig.roomsEndpoint, body);
    return RoomModel.fromJson(data['data']);
  }

  Future<RoomModel> updateRoom(String id, Map<String, dynamic> body) async {
    final data = await _api.put('${ApiConfig.roomsEndpoint}/$id', body);
    return RoomModel.fromJson(data['data']);
  }

  Future<RoomModel> updateRoomStatus(String id, String status) async {
    final data = await _api.patch('${ApiConfig.roomsEndpoint}/$id/status', {'status': status});
    return RoomModel.fromJson(data['data']);
  }

  Future<Map<String, dynamic>> getRoomStats() async {
    final data = await _api.get('${ApiConfig.roomsEndpoint}/stats');
    return data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteRoom(String id) async {
    await _api.delete('${ApiConfig.roomsEndpoint}/$id');
  }
}
