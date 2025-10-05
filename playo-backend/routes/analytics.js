const express = require('express');
const db = require('../utils/db');

const router = express.Router();

// GET all user profiles (from view)
router.get('/profiles', (req, res) => {
    db.query('SELECT * FROM user_profile_view ORDER BY Name', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET all venue details (from view)
router.get('/venue-details', (req, res) => {
    db.query('SELECT * FROM venue_details_view ORDER BY VenueName', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET available timeslots (from view)
router.get('/available-timeslots', (req, res) => {
    const { sport, date } = req.query;
    
    let query = 'SELECT * FROM available_timeslots_view WHERE 1=1';
    let params = [];
    
    if (sport) {
        query += ' AND SportName = ?';
        params.push(sport);
    }
    
    if (date) {
        query += ' AND Date = ?';
        params.push(date);
    }
    
    query += ' ORDER BY Date, StartTime';
    
    db.query(query, params, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET booking summaries (from view)
router.get('/booking-summaries', (req, res) => {
    const { userId, status } = req.query;
    
    let query = 'SELECT * FROM booking_summary_view WHERE 1=1';
    let params = [];
    
    if (userId) {
        query += ' AND PlayerName IN (SELECT Name FROM Users WHERE UserID = ?)';
        params.push(userId);
    }
    
    if (status) {
        query += ' AND BookingStatus = ?';
        params.push(status);
    }
    
    query += ' ORDER BY BookingDate DESC';
    
    db.query(query, params, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET popular sports (from view)
router.get('/popular-sports', (req, res) => {
    db.query('SELECT * FROM popular_sports_view', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET analytics - venue utilization
router.get('/venue-utilization', (req, res) => {
    const query = `
        SELECT 
            v.VenueName,
            DATE(ts.Date) as BookingDate,
            COUNT(ts.TimeslotID) as TotalSlots,
            COUNT(b.BookingID) as BookedSlots,
            ROUND((COUNT(b.BookingID) / COUNT(ts.TimeslotID)) * 100, 2) as UtilizationRate
        FROM Venues v
        JOIN Timeslots ts ON v.VenueID = ts.VenueID
        LEFT JOIN Bookings b ON ts.TimeslotID = b.TimeslotID
        WHERE ts.Date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY v.VenueID, DATE(ts.Date)
        ORDER BY BookingDate DESC, UtilizationRate DESC
        LIMIT 50
    `;
    
    db.query(query, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET analytics - peak hours
router.get('/peak-hours', (req, res) => {
    const query = `
        SELECT 
            HOUR(ts.StartTime) as HourOfDay,
            s.SportName,
            COUNT(b.BookingID) as BookingCount,
            AVG(ts.PricePerHour) as AvgPrice
        FROM Timeslots ts
        JOIN Venues v ON ts.VenueID = v.VenueID
        JOIN Sports s ON v.SportID = s.SportID
        JOIN Bookings b ON ts.TimeslotID = b.TimeslotID
        GROUP BY HOUR(ts.StartTime), s.SportName
        ORDER BY BookingCount DESC
    `;
    
    db.query(query, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

module.exports = router;