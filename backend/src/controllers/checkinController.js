const { query, getClient } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/response');

const getAllCheckins = async (req, res, next) => {
  try {
    const { status } = req.query;
    let sql = `SELECT c.*, g.name as guest_name, g.phone as guest_phone,
               r.room_number, r.room_type, r.floor
               FROM checkins c
               JOIN guests g ON c.guest_id = g.id
               JOIN rooms r ON c.room_id = r.id
               WHERE 1=1`;
    const params = [];
    if (status) { sql += ' AND c.status = $1'; params.push(status); }
    sql += ' ORDER BY c.check_in_date DESC';
    const result = await query(sql, params);
    return successResponse(res, result.rows);
  } catch (err) { next(err); }
};

const getActiveCheckins = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT c.*, g.name as guest_name, g.phone as guest_phone, g.email as guest_email,
              r.room_number, r.room_type, r.floor, r.price_per_night
       FROM checkins c
       JOIN guests g ON c.guest_id = g.id
       JOIN rooms r ON c.room_id = r.id
       WHERE c.status = 'active'
       ORDER BY c.check_in_date DESC`
    );
    return successResponse(res, result.rows);
  } catch (err) { next(err); }
};

const getCheckinById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT c.*, g.name as guest_name, g.phone as guest_phone, g.email as guest_email,
              g.address as guest_address, g.id_proof_type, g.id_proof_number, g.id_proof_image_url,
              r.room_number, r.room_type, r.floor, r.price_per_night, r.amenities
       FROM checkins c
       JOIN guests g ON c.guest_id = g.id
       JOIN rooms r ON c.room_id = r.id
       WHERE c.id = $1`,
      [id]
    );
    if (result.rows.length === 0) return errorResponse(res, 'Check-in not found', 404);
    const checkin = result.rows[0];
    const invoiceResult = await query('SELECT * FROM invoices WHERE checkin_id=$1', [id]);
    checkin.invoice = invoiceResult.rows[0] || null;
    return successResponse(res, checkin);
  } catch (err) { next(err); }
};

const createCheckin = async (req, res, next) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');
    const { room_id, guest, check_in_date, check_out_date, adults = 1, children = 0, special_requests } = req.body;
    if (!room_id || !guest || !check_in_date || !check_out_date) {
      return errorResponse(res, 'room_id, guest, check_in_date, check_out_date are required', 400);
    }
    // Validate room availability
    const roomResult = await client.query("SELECT * FROM rooms WHERE id=$1", [room_id]);
    if (roomResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return errorResponse(res, 'Room not found', 404);
    }
    if (roomResult.rows[0].status !== 'available') {
      await client.query('ROLLBACK');
      return errorResponse(res, `Room is currently ${roomResult.rows[0].status}`, 400);
    }
    // Create or find guest
    let guestId;
    if (guest.id) {
      guestId = guest.id;
    } else {
      const guestResult = await client.query(
        `INSERT INTO guests (name, email, phone, address, id_proof_type, id_proof_number, nationality)
         VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
        [guest.name, guest.email, guest.phone, guest.address, guest.id_proof_type, guest.id_proof_number, guest.nationality]
      );
      guestId = guestResult.rows[0].id;
    }
    // Create check-in
    const checkinResult = await client.query(
      `INSERT INTO checkins (guest_id, room_id, checked_in_by, check_in_date, check_out_date, adults, children, special_requests, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'active') RETURNING *`,
      [guestId, room_id, req.user.id, check_in_date, check_out_date, adults, children, special_requests]
    );
    // Update room status
    await client.query("UPDATE rooms SET status='occupied', updated_at=NOW() WHERE id=$1", [room_id]);
    await client.query('COMMIT');
    // Fetch full checkin details
    const fullResult = await query(
      `SELECT c.*, g.name as guest_name, g.phone as guest_phone,
              r.room_number, r.room_type, r.price_per_night
       FROM checkins c JOIN guests g ON c.guest_id=g.id JOIN rooms r ON c.room_id=r.id
       WHERE c.id=$1`,
      [checkinResult.rows[0].id]
    );
    return successResponse(res, fullResult.rows[0], 'Check-in successful', 201);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
};

const checkOut = async (req, res, next) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');
    const { id } = req.params;
    const checkinResult = await client.query(
      `SELECT c.*, r.price_per_night FROM checkins c JOIN rooms r ON c.room_id=r.id WHERE c.id=$1`,
      [id]
    );
    if (checkinResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return errorResponse(res, 'Check-in not found', 404);
    }
    const checkin = checkinResult.rows[0];
    if (checkin.status !== 'active') {
      await client.query('ROLLBACK');
      return errorResponse(res, 'Check-in is not active', 400);
    }
    const checkoutTime = new Date();
    const checkInDate = new Date(checkin.check_in_date);
    const nights = Math.max(1, Math.ceil((checkoutTime - checkInDate) / (1000 * 60 * 60 * 24)));
    const roomCharges = nights * parseFloat(checkin.price_per_night);
    const cgstRate = 9, sgstRate = 9;
    const subtotal = roomCharges;
    const cgstAmount = (subtotal * cgstRate) / 100;
    const sgstAmount = (subtotal * sgstRate) / 100;
    const totalAmount = subtotal + cgstAmount + sgstAmount;

    // Generate invoice
    let invoiceResult = await client.query('SELECT * FROM invoices WHERE checkin_id=$1', [id]);
    let invoice;
    if (invoiceResult.rows.length === 0) {
      invoiceResult = await client.query(
        `INSERT INTO invoices
         (checkin_id, guest_id, room_charges, extra_charges, discount, subtotal,
          cgst_rate, sgst_rate, cgst_amount, sgst_amount, total_amount, payment_status)
         VALUES ($1,$2,$3,0,0,$4,$5,$6,$7,$8,$9,'pending') RETURNING *`,
        [id, checkin.guest_id, roomCharges, subtotal, cgstRate, sgstRate, cgstAmount, sgstAmount, totalAmount]
      );
      invoice = invoiceResult.rows[0];
    } else {
      invoice = invoiceResult.rows[0];
    }
    // Update checkin
    await client.query(
      "UPDATE checkins SET status='checked_out', actual_checkout=$1, updated_at=NOW() WHERE id=$2",
      [checkoutTime, id]
    );
    // Update room to cleaning
    await client.query("UPDATE rooms SET status='cleaning', updated_at=NOW() WHERE id=$1", [checkin.room_id]);
    await client.query('COMMIT');
    return successResponse(res, { checkin_id: id, invoice, nights }, 'Check-out successful');
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
};

module.exports = { getAllCheckins, getActiveCheckins, getCheckinById, createCheckin, checkOut };
