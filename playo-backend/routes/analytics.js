// Import required modules
const express = require('express');        // Web framework for creating routes
const db = require('../utils/db');        // Database connection pool

// Create router instance for analytics endpoints
const router = express.Router();

// GET /api/analytics/profiles - Fetch all user profiles with role information
// Uses the user_profile_view database view for optimized queries
router.get('/profiles', (req, res) => {
    // Query the user_profile_view which joins Users and Roles tables
    db.query('SELECT * FROM user_profile_view ORDER BY Name', (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return user profiles as JSON array
    });
});

// GET /api/analytics/venue-details - Fetch enhanced venue information
// Uses venue_details_view for comprehensive venue data with owner information
router.get('/venue-details', (req, res) => {
    // Query venue_details_view which includes venue and owner information
    db.query('SELECT * FROM venue_details_view ORDER BY VenueName', (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return venue details as JSON array sorted by name
    });
});

// GET /api/analytics/available-timeslots - Fetch available booking slots with filtering
// Supports query parameters: ?sport=Cricket&date=2025-10-05
router.get('/available-timeslots', (req, res) => {
    // Extract query parameters for filtering
    const { sport, date } = req.query;
    
    // Build dynamic query starting with base view
    let query = 'SELECT * FROM available_timeslots_view WHERE 1=1'; // 1=1 allows easy AND conditions
    let params = []; // Array to store parameter values for safe SQL binding
    
    // Add sport filter if provided
    if (sport) {
        query += ' AND SportName = ?'; // Use parameterized query to prevent SQL injection
        params.push(sport); // Add sport name to parameters array
    }
    
    // Add date filter if provided
    if (date) {
        query += ' AND Date = ?'; // Add date condition with parameter binding
        params.push(date); // Add date to parameters array
    }
    
    // Add sorting for logical display order
    query += ' ORDER BY Date, StartTime'; // Sort by date first, then time
    
    // Execute the dynamically built query with parameters
    db.query(query, params, (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return filtered timeslots as JSON
    });
});

// GET /api/analytics/booking-summaries - Fetch booking analytics with filtering
// Supports query parameters: ?userId=123&status=confirmed
router.get('/booking-summaries', (req, res) => {
    // Extract filtering parameters from query string
    const { userId, status } = req.query;
    
    // Start with base query from booking summary view
    let query = 'SELECT * FROM booking_summary_view WHERE 1=1';
    let params = []; // Parameters array for safe SQL binding
    
    // Filter by specific user if userId provided
    if (userId) {
        // Use subquery to match user ID with player name in view
        query += ' AND PlayerName IN (SELECT Name FROM Users WHERE UserID = ?)';
        params.push(userId); // Add user ID to parameters
    }
    
    // Filter by booking status if provided (e.g., 'confirmed', 'pending', 'cancelled')
    if (status) {
        query += ' AND BookingStatus = ?'; // Add status filter with parameter binding
        params.push(status); // Add status to parameters
    }
    
    // Sort by most recent bookings first for better user experience
    query += ' ORDER BY BookingDate DESC';
    
    // Execute filtered query with parameter binding for security
    db.query(query, params, (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return filtered booking summaries as JSON
    });
});

// GET /api/analytics/popular-sports - Fetch sports popularity rankings
// Uses popular_sports_view to show booking counts and popularity metrics
router.get('/popular-sports', (req, res) => {
    // Query the popular_sports_view which aggregates booking data by sport
    db.query('SELECT * FROM popular_sports_view', (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return sports popularity data as JSON
    });
});

// GET /api/analytics/venue-utilization - Calculate venue usage efficiency metrics
// Provides utilization rates for business intelligence and revenue optimization
router.get('/venue-utilization', (req, res) => {
    // Complex analytical query to calculate venue utilization percentages
    const query = `
        SELECT 
            v.VenueName,                                           -- Venue name for identification
            DATE(ts.Date) as BookingDate,                         -- Date for time-series analysis
            COUNT(ts.TimeslotID) as TotalSlots,                   -- Total available slots per day
            COUNT(b.BookingID) as BookedSlots,                    -- Actually booked slots per day
            ROUND((COUNT(b.BookingID) / COUNT(ts.TimeslotID)) * 100, 2) as UtilizationRate -- Efficiency percentage
        FROM Venues v                                             -- Main venues table
        JOIN Timeslots ts ON v.VenueID = ts.VenueID             -- Get all timeslots for each venue
        LEFT JOIN Bookings b ON ts.TimeslotID = b.TimeslotID     -- LEFT JOIN to include unbooked slots
        WHERE ts.Date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)    -- Last 30 days only for relevance
        GROUP BY v.VenueID, DATE(ts.Date)                        -- Group by venue and date for daily metrics
        ORDER BY BookingDate DESC, UtilizationRate DESC          -- Sort by recent dates and high utilization
        LIMIT 50                                                 -- Limit results for performance
    `;
    
    // Execute the analytical query
    db.query(query, (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return utilization analytics as JSON
    });
});

// GET /api/analytics/peak-hours - Analyze booking patterns by time and sport
// Helps identify popular time slots for pricing optimization and resource allocation
router.get('/peak-hours', (req, res) => {
    // Analytical query to find peak booking hours for different sports
    const query = `
        SELECT 
            HOUR(ts.StartTime) as HourOfDay,                     -- Extract hour (0-23) from timestamp
            s.SportName,                                         -- Sport type for segmented analysis
            COUNT(b.BookingID) as BookingCount,                  -- Number of bookings per hour/sport
            AVG(ts.PricePerHour) as AvgPrice                     -- Average pricing for the time slot
        FROM Timeslots ts                                        -- Main timeslots table
        JOIN Venues v ON ts.VenueID = v.VenueID                 -- Join venues to get sport information
        JOIN Sports s ON v.SportID = s.SportID                  -- Join sports to get sport names
        JOIN Bookings b ON ts.TimeslotID = b.TimeslotID         -- Only include booked timeslots
        GROUP BY HOUR(ts.StartTime), s.SportName                -- Group by hour and sport for aggregation
        ORDER BY BookingCount DESC                              -- Sort by most popular hours first
    `;
    
    // Execute peak hours analysis query
    db.query(query, (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return peak hours analytics as JSON
    });
});

// Export router for use in main server application
module.exports = router;