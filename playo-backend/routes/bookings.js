const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    db.query('SELECT * FROM Bookings', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Bookings WHERE BookingID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { VenueID, TeamID, BookingDate, TimeSlot } = req.body;
    
    // First, find or create the time slot
    const slotQuery = `
        SELECT SlotID FROM timeslots 
        WHERE VenueID = ? 
        AND DATE(StartTime) = ? 
        AND TIME(StartTime) = ?
        AND Status = 'Available'
        LIMIT 1
    `;
    
    db.query(slotQuery, [VenueID, BookingDate, TimeSlot], (err, slots) => {
        if(err) return res.status(500).json({ error: err });
        
        if(slots.length === 0) {
            return res.status(400).json({ error: 'Time slot not available' });
        }
        
        const slotId = slots[0].SlotID;
        
        // Calculate cost based on venue type (simplified)
        let cost = 1000; // Default cost
        if (VenueID <= 2) cost = 1500; // Basketball/Football
        if (VenueID >= 3 && VenueID <= 4) cost = 1200; // Tennis/Badminton
        if (VenueID === 5) cost = 2500; // Cricket
        
        // Create booking
        db.query('INSERT INTO bookings (TeamID, SlotID, BookingDate, BookingCost) VALUES (?, ?, ?, ?)',
            [TeamID, slotId, new Date(), cost],
            (err, result) => {
                if(err) return res.status(500).json({ error: err });
                
                // Update slot status to booked
                db.query('UPDATE timeslots SET Status = "Booked" WHERE SlotID = ?', [slotId], (err2) => {
                    if(err2) console.log('Warning: Could not update slot status');
                });
                
                res.json({ message: 'Booking created', BookingID: result.insertId });
            }
        );
    });
});

router.put('/update/:id', (req, res) => {
    const { TeamID, SlotID, BookingDate, BookingCost, PaymentID } = req.body;
    db.query('UPDATE Bookings SET TeamID=?, SlotID=?, BookingDate=?, BookingCost=?, PaymentID=? WHERE BookingID=?',
        [TeamID, SlotID, BookingDate, BookingCost, PaymentID, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Booking updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Bookings WHERE BookingID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Booking deleted' });
    });
});

module.exports = router;
