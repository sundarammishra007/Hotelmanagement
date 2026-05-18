const router = require('express').Router();
const ctrl = require('../controllers/guestController');
const { authenticate } = require('../middleware/auth');
const { upload } = require('../config/cloudinary');

router.use(authenticate);
router.get('/', ctrl.getAllGuests);
router.get('/search', ctrl.searchGuests);
router.get('/:id', ctrl.getGuestById);
router.post('/', upload.single('id_proof'), ctrl.createGuest);
router.put('/:id', upload.single('id_proof'), ctrl.updateGuest);

module.exports = router;
