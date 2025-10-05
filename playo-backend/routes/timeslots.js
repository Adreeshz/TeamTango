const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    db.query('SELECT * FROM TimeSlots', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM TimeSlots WHERE SlotID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { VenueID, StartTime, EndTime, Status } = req.body;
    db.query('INSERT INTO TimeSlots (VenueID, StartTime, EndTime, Status) VALUES (?, ?, ?, ?)',
        [VenueID, StartTime, EndTime, Status],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'TimeSlot created', SlotID: result.insertId });
        }
    );
});

router.put('/update/:id', (req, res) => {
    const { VenueID, StartTime, EndTime, Status } = req.body;
    db.query('UPDATE TimeSlots SET VenueID=?, StartTime=?, EndTime=?, Status=? WHERE SlotID=?',
        [VenueID, StartTime, EndTime, Status, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'TimeSlot updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM TimeSlots WHERE SlotID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'TimeSlot deleted' });
    });
});

module.exports = router;
