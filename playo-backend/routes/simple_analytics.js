const express = require('express');
const db = require('../utils/db');

const router = express.Router();

// Simple analytics without complex views
router.get('/dashboard-stats', (req, res) => {
    // Get basic counts with simple queries
    const queries = {
        users: 'SELECT COUNT(*) as count FROM Users',
        venues: 'SELECT COUNT(*) as count FROM Venues', 
        bookings: 'SELECT COUNT(*) as count FROM Bookings',
        sports: 'SELECT COUNT(*) as count FROM Sports'
    };
    
    const results = {};
    let completed = 0;
    
    Object.keys(queries).forEach(key => {
        db.query(queries[key], (err, result) => {
            if (!err) results[key] = result[0].count;
            completed++;
            
            if (completed === Object.keys(queries).length) {
                res.json(results);
            }
        });
    });
});

// Get bookings with player info (simple join)
router.get('/recent-bookings', (req, res) => {
    const query = `
        SELECT 
            b.BookingID,
            u.Name as PlayerName,
            b.TotalAmount,
            b.BookingStatus,
            b.CreatedAt
        FROM Bookings b
        JOIN Users u ON b.UserID = u.UserID
        ORDER BY b.CreatedAt DESC
        LIMIT 10
    `;
    
    db.query(query, (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// Get available slots (simple join)
router.get('/available-today', (req, res) => {
    const today = new Date().toISOString().split('T')[0];
    
    const query = `
        SELECT 
            ts.TimeslotID,
            v.VenueName,
            ts.StartTime,
            ts.EndTime,
            ts.PricePerHour
        FROM Timeslots ts
        JOIN Venues v ON ts.VenueID = v.VenueID
        WHERE ts.Date = ? AND ts.IsBooked = FALSE
        ORDER BY ts.StartTime
        LIMIT 10
    `;
    
    db.query(query, [today], (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

module.exports = router;