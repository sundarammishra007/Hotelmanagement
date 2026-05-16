const { query } = require('../config/db');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');

const getAllGuests = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;
    let sql = 'SELECT * FROM guests WHERE 1=1';
    const params = [];
    let idx = 1;
    if (search) {
      sql += ` AND (name ILIKE $${idx} OR phone ILIKE $${idx} OR email ILIKE $${idx})`;
      params.push(`%${search}%`); idx++;
    }
    const countResult = await query(sql.replace('SELECT *', 'SELECT COUNT(*)'), params);
    sql += ` ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`;
    params.push(limit, offset);
    const result = await query(sql, params);
    return paginatedResponse(res, result.rows, parseInt(countResult.rows[0].count), page, limit);
  } catch (err) { next(err); }
};

const getGuestById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const guestResult = await query('SELECT * FROM guests WHERE id=$1', [id]);
    if (guestResult.rows.length === 0) return errorResponse(res, 'Guest not found', 404);
    const checkinResult = await query(
      `SELECT c.*, r.room_number, r.room_type FROM checkins c
       JOIN rooms r ON c.room_id = r.id WHERE c.guest_id=$1 ORDER BY c.check_in_date DESC`,
      [id]
    );
    return successResponse(res, { ...guestResult.rows[0], checkin_history: checkinResult.rows });
  } catch (err) { next(err); }
};

const createGuest = async (req, res, next) => {
  try {
    const { name, email, phone, address, id_proof_type, id_proof_number, nationality } = req.body;
    if (!name || !phone) return errorResponse(res, 'Name and phone are required', 400);
    const id_proof_image_url = req.file ? req.file.path : null;
    const result = await query(
      `INSERT INTO guests (name, email, phone, address, id_proof_type, id_proof_number, id_proof_image_url, nationality)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [name, email, phone, address, id_proof_type, id_proof_number, id_proof_image_url, nationality]
    );
    return successResponse(res, result.rows[0], 'Guest created successfully', 201);
  } catch (err) { next(err); }
};

const updateGuest = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, email, phone, address, id_proof_type, id_proof_number, nationality } = req.body;
    const id_proof_image_url = req.file ? req.file.path : undefined;
    const fields = ['name=$1', 'email=$2', 'phone=$3', 'address=$4', 'id_proof_type=$5',
                    'id_proof_number=$6', 'nationality=$7', 'updated_at=NOW()'];
    const params = [name, email, phone, address, id_proof_type, id_proof_number, nationality];
    if (id_proof_image_url) { fields.push(`id_proof_image_url=$${params.length + 1}`); params.push(id_proof_image_url); }
    params.push(id);
    const result = await query(
      `UPDATE guests SET ${fields.join(',')} WHERE id=$${params.length} RETURNING *`, params
    );
    if (result.rows.length === 0) return errorResponse(res, 'Guest not found', 404);
    return successResponse(res, result.rows[0], 'Guest updated successfully');
  } catch (err) { next(err); }
};

const searchGuests = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q) return errorResponse(res, 'Search query is required', 400);
    const result = await query(
      `SELECT * FROM guests WHERE name ILIKE $1 OR phone ILIKE $1 OR email ILIKE $1 LIMIT 10`,
      [`%${q}%`]
    );
    return successResponse(res, result.rows);
  } catch (err) { next(err); }
};

module.exports = { getAllGuests, getGuestById, createGuest, updateGuest, searchGuests };
