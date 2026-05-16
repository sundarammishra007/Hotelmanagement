const { query } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/response');

const getAllRooms = async (req, res, next) => {
  try {
    const { status, room_type, floor } = req.query;
    let sql = 'SELECT * FROM rooms WHERE 1=1';
    const params = [];
    let idx = 1;
    if (status) { sql += ` AND status = $${idx++}`; params.push(status); }
    if (room_type) { sql += ` AND room_type = $${idx++}`; params.push(room_type); }
    if (floor) { sql += ` AND floor = $${idx++}`; params.push(floor); }
    sql += ' ORDER BY floor, room_number';
    const result = await query(sql, params);
    return successResponse(res, result.rows);
  } catch (err) { next(err); }
};

const getRoomById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const roomResult = await query('SELECT * FROM rooms WHERE id = $1', [id]);
    if (roomResult.rows.length === 0) return errorResponse(res, 'Room not found', 404);
    const room = roomResult.rows[0];
    if (room.status === 'occupied') {
      const checkinResult = await query(
        `SELECT c.*, g.name as guest_name, g.phone as guest_phone
         FROM checkins c JOIN guests g ON c.guest_id = g.id
         WHERE c.room_id = $1 AND c.status = 'active' LIMIT 1`,
        [id]
      );
      room.current_checkin = checkinResult.rows[0] || null;
    }
    return successResponse(res, room);
  } catch (err) { next(err); }
};

const createRoom = async (req, res, next) => {
  try {
    const { room_number, floor, room_type, price_per_night, amenities, description, max_occupancy } = req.body;
    if (!room_number || !floor || !room_type || !price_per_night) {
      return errorResponse(res, 'room_number, floor, room_type, and price_per_night are required', 400);
    }
    const result = await query(
      `INSERT INTO rooms (room_number, floor, room_type, price_per_night, amenities, description, max_occupancy)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [room_number, floor, room_type, price_per_night, amenities || [], description, max_occupancy || 2]
    );
    return successResponse(res, result.rows[0], 'Room created successfully', 201);
  } catch (err) { next(err); }
};

const updateRoom = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { floor, room_type, price_per_night, amenities, description, max_occupancy } = req.body;
    const result = await query(
      `UPDATE rooms SET floor=$1, room_type=$2, price_per_night=$3, amenities=$4,
       description=$5, max_occupancy=$6, updated_at=NOW()
       WHERE id=$7 RETURNING *`,
      [floor, room_type, price_per_night, amenities, description, max_occupancy, id]
    );
    if (result.rows.length === 0) return errorResponse(res, 'Room not found', 404);
    return successResponse(res, result.rows[0], 'Room updated successfully');
  } catch (err) { next(err); }
};

const updateRoomStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const validStatuses = ['available', 'occupied', 'cleaning', 'maintenance'];
    if (!validStatuses.includes(status)) {
      return errorResponse(res, `Status must be one of: ${validStatuses.join(', ')}`, 400);
    }
    const result = await query(
      'UPDATE rooms SET status=$1, updated_at=NOW() WHERE id=$2 RETURNING *',
      [status, id]
    );
    if (result.rows.length === 0) return errorResponse(res, 'Room not found', 404);
    return successResponse(res, result.rows[0], 'Room status updated');
  } catch (err) { next(err); }
};

const deleteRoom = async (req, res, next) => {
  try {
    const { id } = req.params;
    const active = await query(
      "SELECT id FROM checkins WHERE room_id=$1 AND status='active'", [id]
    );
    if (active.rows.length > 0) {
      return errorResponse(res, 'Cannot delete room with active check-in', 400);
    }
    await query('DELETE FROM rooms WHERE id=$1', [id]);
    return successResponse(res, null, 'Room deleted successfully');
  } catch (err) { next(err); }
};

const getRoomStats = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT
        COUNT(*) FILTER (WHERE status='available') as available,
        COUNT(*) FILTER (WHERE status='occupied') as occupied,
        COUNT(*) FILTER (WHERE status='cleaning') as cleaning,
        COUNT(*) FILTER (WHERE status='maintenance') as maintenance,
        COUNT(*) as total
       FROM rooms`
    );
    return successResponse(res, result.rows[0]);
  } catch (err) { next(err); }
};

module.exports = { getAllRooms, getRoomById, createRoom, updateRoom, updateRoomStatus, deleteRoom, getRoomStats };
