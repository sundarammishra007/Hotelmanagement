const PDFDocument = require('pdfkit');

const generateInvoicePDF = (invoice, guest, room, payments, hotelInfo) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50, size: 'A4' });
      const buffers = [];
      doc.on('data', chunk => buffers.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', reject);

      const primaryColor = '#1E3A5F';
      const accentColor = '#F5A623';
      const lightGray = '#F5F5F5';
      const darkGray = '#333333';
      const pageWidth = doc.page.width - 100;

      // ── Header ──────────────────────────────────────────────
      doc.rect(0, 0, doc.page.width, 100).fill(primaryColor);
      doc.fill('white').fontSize(22).font('Helvetica-Bold')
         .text(hotelInfo.name || 'My Hotel', 50, 25);
      doc.fontSize(9).font('Helvetica')
         .text(hotelInfo.address || '', 50, 52)
         .text(`Phone: ${hotelInfo.phone || ''}  |  GST: ${hotelInfo.gstNumber || ''}`, 50, 66);

      doc.fill(accentColor).fontSize(18).font('Helvetica-Bold')
         .text('TAX INVOICE', 0, 35, { align: 'right', width: doc.page.width - 50 });

      doc.moveDown(3);

      // ── Invoice Meta ──────────────────────────────────────────────
      doc.fill(darkGray).fontSize(10).font('Helvetica-Bold');
      const metaY = 120;
      doc.text('Invoice Number:', 50, metaY).font('Helvetica')
         .text(invoice.invoice_number || invoice.invoiceNumber, 160, metaY);
      doc.font('Helvetica-Bold')
         .text('Invoice Date:', 50, metaY + 18).font('Helvetica')
         .text(new Date(invoice.created_at || invoice.createdAt).toLocaleDateString('en-IN'), 160, metaY + 18);
      doc.font('Helvetica-Bold')
         .text('Payment Status:', 50, metaY + 36).font('Helvetica')
         .text((invoice.payment_status || invoice.paymentStatus || '').toUpperCase(), 160, metaY + 36);

      // ── Guest Details ──────────────────────────────────────────────
      const guestY = metaY + 70;
      doc.rect(50, guestY, pageWidth, 22).fill(primaryColor);
      doc.fill('white').fontSize(10).font('Helvetica-Bold')
         .text('GUEST DETAILS', 60, guestY + 6);

      const guestRows = [
        ['Guest Name', guest.name],
        ['Phone', guest.phone],
        ['Email', guest.email || 'N/A'],
        ['ID Proof', `${guest.id_proof_type || ''} - ${guest.id_proof_number || ''}`],
        ['Address', guest.address || 'N/A'],
      ];
      let rowY = guestY + 28;
      guestRows.forEach((row, i) => {
        if (i % 2 === 0) doc.rect(50, rowY - 2, pageWidth, 18).fill(lightGray);
        doc.fill(darkGray).font('Helvetica-Bold').fontSize(9).text(row[0], 60, rowY);
        doc.font('Helvetica').text(row[1], 200, rowY);
        rowY += 18;
      });

      // ── Room Details ──────────────────────────────────────────────
      const roomY = rowY + 15;
      doc.rect(50, roomY, pageWidth, 22).fill(primaryColor);
      doc.fill('white').fontSize(10).font('Helvetica-Bold')
         .text('ROOM & STAY DETAILS', 60, roomY + 6);

      const nights = invoice.nights || Math.ceil(
        (new Date(invoice.check_out_date) - new Date(invoice.check_in_date)) / (1000 * 60 * 60 * 24)
      );
      const roomRows = [
        ['Room Number', room.room_number || room.roomNumber],
        ['Room Type', (room.room_type || room.roomType || '').toUpperCase()],
        ['Floor', `Floor ${room.floor}`],
        ['Check-in Date', new Date(invoice.check_in_date || '').toLocaleDateString('en-IN')],
        ['Check-out Date', new Date(invoice.check_out_date || '').toLocaleDateString('en-IN')],
        ['Total Nights', `${nights} Night(s)`],
        ['Rate per Night', `₹ ${parseFloat(room.price_per_night || room.pricePerNight || 0).toFixed(2)}`],
      ];
      let rRowY = roomY + 28;
      roomRows.forEach((row, i) => {
        if (i % 2 === 0) doc.rect(50, rRowY - 2, pageWidth, 18).fill(lightGray);
        doc.fill(darkGray).font('Helvetica-Bold').fontSize(9).text(row[0], 60, rRowY);
        doc.font('Helvetica').text(row[1], 200, rRowY);
        rRowY += 18;
      });

      // ── Charges Table ──────────────────────────────────────────────
      const chargesY = rRowY + 15;
      doc.rect(50, chargesY, pageWidth, 22).fill(primaryColor);
      doc.fill('white').fontSize(10).font('Helvetica-Bold')
         .text('CHARGES BREAKDOWN', 60, chargesY + 6);

      const roomCharges = parseFloat(invoice.room_charges || invoice.roomCharges || 0);
      const extraCharges = parseFloat(invoice.extra_charges || invoice.extraCharges || 0);
      const discount = parseFloat(invoice.discount || 0);
      const subtotal = parseFloat(invoice.subtotal || 0);
      const cgstAmount = parseFloat(invoice.cgst_amount || invoice.cgstAmount || 0);
      const sgstAmount = parseFloat(invoice.sgst_amount || invoice.sgstAmount || 0);
      const total = parseFloat(invoice.total_amount || invoice.totalAmount || 0);
      const cgstRate = parseFloat(invoice.cgst_rate || invoice.cgstRate || 9);
      const sgstRate = parseFloat(invoice.sgst_rate || invoice.sgstRate || 9);

      const chargeRows = [
        ['Room Charges', `₹ ${roomCharges.toFixed(2)}`],
        ['Extra Charges', `₹ ${extraCharges.toFixed(2)}`],
        ['Discount', `- ₹ ${discount.toFixed(2)}`],
        ['Subtotal', `₹ ${subtotal.toFixed(2)}`],
        [`CGST (${cgstRate}%)`, `₹ ${cgstAmount.toFixed(2)}`],
        [`SGST (${sgstRate}%)`, `₹ ${sgstAmount.toFixed(2)}`],
      ];

      let cRowY = chargesY + 28;
      chargeRows.forEach((row, i) => {
        if (i % 2 === 0) doc.rect(50, cRowY - 2, pageWidth, 18).fill(lightGray);
        doc.fill(darkGray).font('Helvetica-Bold').fontSize(9).text(row[0], 60, cRowY);
        doc.font('Helvetica').text(row[1], 0, cRowY, { align: 'right', width: doc.page.width - 50 });
        cRowY += 18;
      });

      // Total row
      doc.rect(50, cRowY, pageWidth, 26).fill(accentColor);
      doc.fill('white').fontSize(12).font('Helvetica-Bold')
         .text('TOTAL AMOUNT', 60, cRowY + 7)
         .text(`₹ ${total.toFixed(2)}`, 0, cRowY + 7, { align: 'right', width: doc.page.width - 50 });
      cRowY += 26;

      // ── Payments ──────────────────────────────────────────────
      if (payments && payments.length > 0) {
        const payY = cRowY + 20;
        doc.rect(50, payY, pageWidth, 22).fill(primaryColor);
        doc.fill('white').fontSize(10).font('Helvetica-Bold')
           .text('PAYMENT HISTORY', 60, payY + 6);
        let pRowY = payY + 28;
        payments.forEach((p, i) => {
          if (i % 2 === 0) doc.rect(50, pRowY - 2, pageWidth, 18).fill(lightGray);
          doc.fill(darkGray).font('Helvetica-Bold').fontSize(9)
             .text(new Date(p.paid_at).toLocaleDateString('en-IN'), 60, pRowY);
          doc.font('Helvetica')
             .text((p.payment_method || '').toUpperCase(), 200, pRowY)
             .text(`₹ ${parseFloat(p.amount).toFixed(2)}`, 0, pRowY, { align: 'right', width: doc.page.width - 50 });
          pRowY += 18;
        });
      }

      // ── Footer ──────────────────────────────────────────────
      const footerY = doc.page.height - 80;
      doc.rect(0, footerY, doc.page.width, 80).fill(primaryColor);
      doc.fill('white').fontSize(9).font('Helvetica')
         .text('Thank you for choosing us! We hope to see you again.', 0, footerY + 15, { align: 'center' })
         .text(`${hotelInfo.name} | ${hotelInfo.phone} | ${hotelInfo.email || ''}`, 0, footerY + 30, { align: 'center' })
         .text('This is a computer-generated invoice and does not require a signature.', 0, footerY + 45, { align: 'center', fontSize: 8 });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
};

module.exports = { generateInvoicePDF };
