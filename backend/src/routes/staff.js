const router = require('express').Router();
const ctrl = require('../controllers/staffController');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);
router.get('/', ctrl.getAllStaff);
router.get('/attendance/today', ctrl.getAllAttendance);
router.get('/:id', ctrl.getStaffById);
router.post('/', authorize('admin', 'manager'), ctrl.createStaff);
router.put('/:id', authorize('admin', 'manager'), ctrl.updateStaff);
router.post('/:id/attendance', ctrl.markAttendance);
router.get('/:id/attendance', ctrl.getAttendance);

module.exports = router;
