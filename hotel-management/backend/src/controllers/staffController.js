const bcrypt = require('bcryptjs');
const { query, getClient } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/response');

const getAllStaff = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT s.*, u.name, u.email, u.role, u.is_active
       FROM staff s JOIN users u ON s.user_id = u.id
       ORDER BY u.name`
    );
    return successResponse(res, result.rows);
  } catch (err) { next(err); }
};

const getStaffById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const staffResult = await query(
      `SELECT s.*, u.name, u.email, u.role, u.is_active
       FROM staff s JOIN users u ON s.user_id = u.id WHERE s.id=$1`, [id]
    );
    if (staffResult.rows.length === 0) return errorResponse(res, 'Staff not found', 404);
    const attendance = await query(
      'SELECT * FROM staff_attendance WHERE staff_id=$1 ORDER BY date DESC LIMIT 30', [id]
    );
    return successResponse(res, { ...staffResult.rows[0], recent_attendance: attendance.rows });
  } catch (err) { next(err); }
};

const createStaff = async (req, res, next) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');
    const { name, email, password = 'staff123', role, employee_id, phone, address, joining_date, department, shift } = req.body;
    if (!name || !email || !role || !employee_id) {
      return errorResponse(res, 'name, email, role, employee_id are required', 400);
    }
    const hash = await bcrypt.hash(password, 12);
    const userResult = await client.query(
      `INSERT INTO users (name, email, password_hash, role) VALUES ($1,$2,$3,$4) RETURNING id`,
      [name, email.toLowerCase(), hash, role]
    );
    const staffResult = await client.query(
      `INSERT INTO staff (user_id, employee_id, phone, address, joining_date, department, shift)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [userResult.rows[0].id, employee_id, phone, address, joining_date || new Date(), department, shift || 'morning']
    );
    await client.query('COMMIT');
    return successResponse(res, { ...staffResult.rows[0], name, email, role }, 'Staff created. Default password: staff123', 201);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
};

const updateStaff = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { phone, address, department, shift } = req.body;
    const result = await query(
      `UPDATE staff SET phone=$1, address=$2, department=$3, shift=$4, updated_at=NOW()
       WHERE id=$5 RETURNING *`,
      [phone, address, department, shift, id]
    );
    if (result.rows.length === 0) return errorResponse(res, 'Staff not found', 404);
    return successResponse(res, result.rows[0], 'Staff updated');
  } catch (err) { next(err); }
};

const markAttendance = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status = 'present', check_in_time, check_out_time, notes } = req.body;
    const today = new Date().toISOString().split('T')[0];
    const existing = await query(
      'SELECT id FROM staff_attendance WHERE staff_id=$1 AND date=$2', [id, today]
    );
    if (existing.rows.length > 0) {
      const updated = await query(
        `UPDATE staff_attendance SET status=$1, check_in_time=$2, check_out_time=$3, notes=$4
         WHERE staff_id=$5 AND date=$6 RETURNING *`,
        [status, check_in_time, check_out_time, notes, id, today]
      );
      return successResponse(res, updated.rows[0], 'Attendance updated');
    }
    const result = await query(
      `INSERT INTO staff_attendance (staff_id, date, status, check_in_time, check_out_time, notes)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [id, today, status, check_in_time || new Date().toTimeString().slice(0, 5), check_out_time, notes]
    );
    return successResponse(res, result.rows[0], 'Attendance marked', 201);
  } catch (err) { next(err); }
};

const getAttendance = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { month } = req.query; // format: YYYY-MM
    let sql = 'SELECT * FROM staff_attendance WHERE staff_id=$1';
    const params = [id];
    if (month) {
      sql += " AND TO_CHAR(date, 'YYYY-MM') = $2";
      params.push(month);
    }
    sql += ' ORDER BY date DESC';
    const result = await query(sql, params);
    return successResponse(res, result.rows);
  } catch (err) { next(err); }
};

const getAllAttendance = async (req, res, next) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const result = await query(
      `SELECT sa.*, u.name, s.employee_id, s.department
       FROM staff_attendance sa
       JOIN staff s ON sa.staff_id = s.id
       JOIN users u ON s.user_id = u.id
       WHERE sa.date = $1 ORDER BY u.name`,
      [today]
    );
    return successResponse(res, result.rows);
  } catch (err) { next(err); }
};

module.exports = { getAllStaff, getStaffById, createStaff, updateStaff, markAttendance, getAttendance, getAllAttendance };
