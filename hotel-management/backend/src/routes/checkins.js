const router = require('express').Router();
const ctrl = require('../controllers/checkinController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);
router.get('/', ctrl.getAllCheckins);
router.get('/active', ctrl.getActiveCheckins);
router.get('/:id', ctrl.getCheckinById);
router.post('/', ctrl.createCheckin);
router.put('/:id/checkout', ctrl.checkOut);

module.exports = router;
