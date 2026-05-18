const { query, getClient } = require('../config/db');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const { generateInvoicePDF } = require('../utils/invoiceGenerator');

const getAllInvoices = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, payment_status } = req.query;
    const offset = (page - 1) * limit;
    let sql = `SELECT i.*, g.name as guest_name, g.phone as guest_phone,
               r.room_number, r.room_type
               FROM invoices i
               JOIN guests g ON i.guest_id = g.id
               JOIN checkins c ON i.checkin_id = c.id
               JOIN rooms r ON c.room_id = r.id
               WHERE 1=1`;
    const params = [];
    let idx = 1;
    if (payment_status) { sql += ` AND i.payment_status = $${idx++}`; params.push(payment_status); }
    const countResult = await query(sql.replace(/SELECT i\.\*.*FROM/, 'SELECT COUNT(*) FROM'), params);
    sql += ` ORDER BY i.created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`;
    params.push(limit, offset);
    const result = await query(sql, params);
    return paginatedResponse(res, result.rows, parseInt(countResult.rows[0].count), page, limit);
  } catch (err) { next(err); }
};

const getInvoiceById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT i.*, g.name as guest_name, g.phone as guest_phone, g.email as guest_email,
              g.address as guest_address, g.id_proof_type, g.id_proof_number,
              r.room_number, r.room_type, r.floor, r.price_per_night,
              c.check_in_date, c.check_out_date, c.actual_checkout, c.adults, c.children
       FROM invoices i
       JOIN guests g ON i.guest_id = g.id
       JOIN checkins c ON i.checkin_id = c.id
       JOIN rooms r ON c.room_id = r.id
       WHERE i.id = $1`,
      [id]
    );
    if (result.rows.length === 0) return errorResponse(res, 'Invoice not found', 404);
    const invoice = result.rows[0];
    const payments = await query('SELECT * FROM payments WHERE invoice_id=$1 ORDER BY paid_at', [id]);
    invoice.payments = payments.rows;
    return successResponse(res, invoice);
  } catch (err) { next(err); }
};

const getInvoiceByCheckinId = async (req, res, next) => {
  try {
    const { checkinId } = req.params;
    const result = await query(
      `SELECT i.*, g.name as guest_name, r.room_number, r.room_type,
              c.check_in_date, c.check_out_date
       FROM invoices i
       JOIN guests g ON i.guest_id = g.id
       JOIN checkins c ON i.checkin_id = c.id
       JOIN rooms r ON c.room_id = r.id
       WHERE i.checkin_id = $1`,
      [checkinId]
    );
    if (result.rows.length === 0) return errorResponse(res, 'Invoice not found for this check-in', 404);
    return successResponse(res, result.rows[0]);
  } catch (err) { next(err); }
};

const generateInvoice = async (req, res, next) => {
  try {
    const { checkin_id, extra_charges = 0, discount = 0, notes } = req.body;
    if (!checkin_id) return errorResponse(res, 'checkin_id is required', 400);
    const checkinResult = await query(
      'SELECT c.*, r.price_per_night FROM checkins c JOIN rooms r ON c.room_id=r.id WHERE c.id=$1',
      [checkin_id]
    );
    if (checkinResult.rows.length === 0) return errorResponse(res, 'Check-in not found', 404);
    const checkin = checkinResult.rows[0];
    const checkOut = checkin.actual_checkout || checkin.check_out_date || new Date();
    const nights = Math.max(1, Math.ceil((new Date(checkOut) - new Date(checkin.check_in_date)) / (1000 * 60 * 60 * 24)));
    const roomCharges = nights * parseFloat(checkin.price_per_night);
    const subtotal = roomCharges + parseFloat(extra_charges) - parseFloat(discount);
    const cgstRate = 9, sgstRate = 9;
    const cgstAmount = (subtotal * cgstRate) / 100;
    const sgstAmount = (subtotal * sgstRate) / 100;
    const totalAmount = subtotal + cgstAmount + sgstAmount;
    // Upsert invoice
    const existing = await query('SELECT id FROM invoices WHERE checkin_id=$1', [checkin_id]);
    let result;
    if (existing.rows.length > 0) {
      result = await query(
        `UPDATE invoices SET room_charges=$1, extra_charges=$2, discount=$3, subtotal=$4,
         cgst_amount=$5, sgst_amount=$6, total_amount=$7, notes=$8, updated_at=NOW()
         WHERE checkin_id=$9 RETURNING *`,
        [roomCharges, extra_charges, discount, subtotal, cgstAmount, sgstAmount, totalAmount, notes, checkin_id]
      );
    } else {
      result = await query(
        `INSERT INTO invoices (checkin_id, guest_id, room_charges, extra_charges, discount, subtotal,
         cgst_rate, sgst_rate, cgst_amount, sgst_amount, total_amount, notes)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
        [checkin_id, checkin.guest_id, roomCharges, extra_charges, discount, subtotal,
         cgstRate, sgstRate, cgstAmount, sgstAmount, totalAmount, notes]
      );
    }
    return successResponse(res, result.rows[0], 'Invoice generated', 201);
  } catch (err) { next(err); }
};

const updateInvoice = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { extra_charges, discount, notes } = req.body;
    const inv = await query('SELECT * FROM invoices WHERE id=$1', [id]);
    if (inv.rows.length === 0) return errorResponse(res, 'Invoice not found', 404);
    const i = inv.rows[0];
    const subtotal = parseFloat(i.room_charges) + parseFloat(extra_charges ?? i.extra_charges) - parseFloat(discount ?? i.discount);
    const cgstAmount = (subtotal * parseFloat(i.cgst_rate)) / 100;
    const sgstAmount = (subtotal * parseFloat(i.sgst_rate)) / 100;
    const totalAmount = subtotal + cgstAmount + sgstAmount;
    const result = await query(
      `UPDATE invoices SET extra_charges=$1, discount=$2, notes=$3, subtotal=$4,
       cgst_amount=$5, sgst_amount=$6, total_amount=$7, updated_at=NOW()
       WHERE id=$8 RETURNING *`,
      [extra_charges ?? i.extra_charges, discount ?? i.discount, notes ?? i.notes,
       subtotal, cgstAmount, sgstAmount, totalAmount, id]
    );
    return successResponse(res, result.rows[0], 'Invoice updated');
  } catch (err) { next(err); }
};

const addPayment = async (req, res, next) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');
    const { id } = req.params;
    const { amount, payment_method, transaction_id, notes } = req.body;
    if (!amount || !payment_method) return errorResponse(res, 'amount and payment_method are required', 400);
    const inv = await client.query('SELECT * FROM invoices WHERE id=$1', [id]);
    if (inv.rows.length === 0) { await client.query('ROLLBACK'); return errorResponse(res, 'Invoice not found', 404); }
    await client.query(
      `INSERT INTO payments (invoice_id, amount, payment_method, transaction_id, received_by, notes)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [id, amount, payment_method, transaction_id, req.user.id, notes]
    );
    // Recalculate payment status
    const paidResult = await client.query('SELECT SUM(amount) as paid FROM payments WHERE invoice_id=$1', [id]);
    const totalPaid = parseFloat(paidResult.rows[0].paid || 0);
    const totalDue = parseFloat(inv.rows[0].total_amount);
    const paymentStatus = totalPaid >= totalDue ? 'paid' : totalPaid > 0 ? 'partial' : 'pending';
    const updated = await client.query(
      "UPDATE invoices SET payment_status=$1, updated_at=NOW() WHERE id=$2 RETURNING *",
      [paymentStatus, id]
    );
    await client.query('COMMIT');
    return successResponse(res, updated.rows[0], 'Payment recorded');
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
};

const downloadInvoicePDF = async (req, res, next) => {
  try {
    const { id } = req.params;
    const invoiceResult = await query(
      `SELECT i.*, c.check_in_date, c.check_out_date, c.actual_checkout, c.adults, c.children
       FROM invoices i JOIN checkins c ON i.checkin_id = c.id WHERE i.id=$1`, [id]
    );
    if (invoiceResult.rows.length === 0) return errorResponse(res, 'Invoice not found', 404);
    const invoice = invoiceResult.rows[0];
    const guestResult = await query('SELECT * FROM guests WHERE id=$1', [invoice.guest_id]);
    const checkinResult = await query('SELECT room_id FROM checkins WHERE id=$1', [invoice.checkin_id]);
    const roomResult = await query('SELECT * FROM rooms WHERE id=$1', [checkinResult.rows[0].room_id]);
    const paymentsResult = await query('SELECT * FROM payments WHERE invoice_id=$1 ORDER BY paid_at', [id]);
    const hotelInfo = {
      name: process.env.HOTEL_NAME || 'My Hotel',
      address: process.env.HOTEL_ADDRESS || '',
      phone: process.env.HOTEL_PHONE || '',
      email: process.env.HOTEL_EMAIL || '',
      gstNumber: process.env.HOTEL_GST_NUMBER || '',
    };
    const pdfBuffer = await generateInvoicePDF(
      invoice, guestResult.rows[0], roomResult.rows[0], paymentsResult.rows, hotelInfo
    );
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="invoice-${invoice.invoice_number}.pdf"`);
    res.setHeader('Content-Length', pdfBuffer.length);
    res.send(pdfBuffer);
  } catch (err) { next(err); }
};

module.exports = { getAllInvoices, getInvoiceById, getInvoiceByCheckinId, generateInvoice, updateInvoice, addPayment, downloadInvoicePDF };
