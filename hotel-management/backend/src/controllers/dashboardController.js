const { query } = require('../config/db');
const { successResponse } = require('../utils/response');

const getDashboardStats = async (req, res, next) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    const [roomStats, checkinStats, revenueStats, recentCheckins] = await Promise.all([
      query(`
        SELECT
          COUNT(*) FILTER (WHERE status='available') as available_rooms,
          COUNT(*) FILTER (WHERE status='occupied') as occupied_rooms,
          COUNT(*) FILTER (WHERE status='cleaning') as cleaning_rooms,
          COUNT(*) FILTER (WHERE status='maintenance') as maintenance_rooms,
          COUNT(*) as total_rooms
        FROM rooms
      `),
      query(`
        SELECT
          COUNT(*) FILTER (WHERE status='active') as active_guests,
          COUNT(*) FILTER (WHERE DATE(actual_checkout)=$1) as checked_out_today,
          COUNT(*) FILTER (WHERE DATE(check_in_date)=$1) as checked_in_today
        FROM checkins
      `, [today]),
      query(`
        SELECT
          COALESCE(SUM(amount) FILTER (WHERE DATE(paid_at)=$1), 0) as revenue_today,
          COALESCE(SUM(amount) FILTER (WHERE DATE_TRUNC('month',paid_at)=DATE_TRUNC('month',NOW())), 0) as revenue_this_month,
          COALESCE(SUM(amount) FILTER (WHERE DATE_TRUNC('year',paid_at)=DATE_TRUNC('year',NOW())), 0) as revenue_this_year
        FROM payments
      `, [today]),
      query(`
        SELECT c.id, c.check_in_date, c.check_out_date, c.status, c.adults,
               g.name as guest_name, g.phone as guest_phone,
               r.room_number, r.room_type, r.floor
        FROM checkins c
        JOIN guests g ON c.guest_id=g.id
        JOIN rooms r ON c.room_id=r.id
        ORDER BY c.check_in_date DESC
        LIMIT 5
      `),
    ]);

    const rooms = roomStats.rows[0];
    const checkins = checkinStats.rows[0];
    const revenue = revenueStats.rows[0];
    const totalRooms = parseInt(rooms.total_rooms);
    const occupiedRooms = parseInt(rooms.occupied_rooms);
    const occupancyRate = totalRooms > 0 ? Math.round((occupiedRooms / totalRooms) * 100) : 0;

    return successResponse(res, {
      activeGuests: parseInt(checkins.active_guests),
      availableRooms: parseInt(rooms.available_rooms),
      occupiedRooms,
      cleaningRooms: parseInt(rooms.cleaning_rooms),
      maintenanceRooms: parseInt(rooms.maintenance_rooms),
      totalRooms,
      checkedOutToday: parseInt(checkins.checked_out_today),
      checkedInToday: parseInt(checkins.checked_in_today),
      revenueToday: parseFloat(revenue.revenue_today),
      revenueThisMonth: parseFloat(revenue.revenue_this_month),
      revenueThisYear: parseFloat(revenue.revenue_this_year),
      occupancyRate,
      recentCheckins: recentCheckins.rows,
    });
  } catch (err) { next(err); }
};

module.exports = { getDashboardStats };
