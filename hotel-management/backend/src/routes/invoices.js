const router = require('express').Router();
const ctrl = require('../controllers/invoiceController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);
router.get('/', ctrl.getAllInvoices);
router.get('/checkin/:checkinId', ctrl.getInvoiceByCheckinId);
router.get('/:id/download', ctrl.downloadInvoicePDF);
router.get('/:id', ctrl.getInvoiceById);
router.post('/generate', ctrl.generateInvoice);
router.put('/:id', ctrl.updateInvoice);
router.post('/:id/payment', ctrl.addPayment);

module.exports = router;
