const router = require('express').Router();
const ctrl = require('../controllers/roomController');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);
router.get('/', ctrl.getAllRooms);
router.get('/stats', ctrl.getRoomStats);
router.get('/:id', ctrl.getRoomById);
router.post('/', authorize('admin', 'manager'), ctrl.createRoom);
router.put('/:id', authorize('admin', 'manager'), ctrl.updateRoom);
router.patch('/:id/status', ctrl.updateRoomStatus);
router.delete('/:id', authorize('admin'), ctrl.deleteRoom);

module.exports = router;
