// Import required modules for booking management functionality
const express = require('express');        // Web framework for creating routes
const router = express.Router();          // Create router instance for booking endpoints
const mysql = require('mysql2/promise');   // MySQL database driver with promise support
const {
    authenticateToken,
    requireAdmin,
    requirePlayerOrAdmin,
    requireAnyRole,
    requireOwnershipOrAdmin,
    logRequest,
    ROLES
} = require('../middleware/auth');

// Database configuration
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '1234',
    database: 'dbms_cp'
};

// Helper function to create database connection
async function createConnection() {
    return await mysql.createConnection(dbConfig);
}

// Apply request logging to all routes
router.use(logRequest);

// GET /api/bookings - Fetch bookings (Role-based access)
// - Players: See only their own bookings
// - Venue Owners: See bookings for their venues
// - Admin: See all bookings
router.get('/', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        // Use booking_details view for simplified query
        let query = `
            SELECT 
                BookingID,
                BookingDate,
                StartTime,
                EndTime,
                BookingStatus as Status,
                UserID,
                PlayerName,
                VenueName,
                VenueLocation as VenueAddress,
                TotalAmount as PaymentAmount,
                PaymentStatus
            FROM booking_details
        `;
        
        let whereConditions = [];
        let queryParams = [];
        
        // Apply role-based filtering
        if (req.user.roleId === ROLES.PLAYER) {
            whereConditions.push('UserID = ?');
            queryParams.push(req.user.userId);
        } else if (req.user.roleId === ROLES.VENUE_OWNER) {
            // Note: venue_summary doesn't have OwnerID, need to join or filter differently
            // For now, we'll need to add a subquery or join back to Venues
            whereConditions.push('VenueID IN (SELECT VenueID FROM Venues WHERE OwnerID = ?)');
            queryParams.push(req.user.userId);
        }
        // Admin sees all bookings (no additional filtering)
        
        if (whereConditions.length > 0) {
            query += ' WHERE ' + whereConditions.join(' AND ');
        }
        
        query += ' ORDER BY BookingDate DESC, StartTime DESC';
        
        const [bookings] = await connection.execute(query, queryParams);
        
        res.json({
            message: 'Bookings retrieved successfully',
            bookings: bookings,
            total: bookings.length
        });
        
    } catch (error) {
        console.error('Get bookings error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve bookings',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/bookings/my - Get current user's bookings (Player only)
router.get('/my', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        let userId = req.user.userId;
        
        // For admin, allow fetching any user's bookings
        if (req.user.roleId === ROLES.ADMIN && req.query.userId) {
            userId = parseInt(req.query.userId);
        }
        
        // Use booking_details view
        const [bookings] = await connection.execute(`
            SELECT 
                BookingID,
                BookingDate,
                TotalAmount,
                StartTime,
                EndTime,
                BookingStatus as Status,
                VenueName,
                VenueLocation as VenueAddress,
                TotalAmount as PaymentAmount,
                PaymentStatus,
                NULL as FeedbackRating,
                NULL as FeedbackComments
            FROM booking_details
            WHERE UserID = ?
            ORDER BY BookingDate DESC, StartTime DESC
        `, [userId]);
        
        res.json({
            message: 'Your bookings retrieved successfully',
            bookings: bookings,
            total: bookings.length
        });
        
    } catch (error) {
        console.error('Get my bookings error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve your bookings',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/bookings/:id - Fetch single booking by ID (Owner or Admin only)
router.get('/:id', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const bookingId = parseInt(req.params.id);
        
        const [bookings] = await connection.execute(`
            SELECT 
                b.*,
                u.Name as PlayerName,
                u.Email as PlayerEmail,
                u.PhoneNumber as PlayerPhone,
                v.VenueName,
                v.Address as VenueAddress,
                v.OwnerID,
                vo.Name as VenueOwnerName,
                ts.SlotDate,
                ts.StartTime,
                ts.EndTime,
                p.Amount as PaymentAmount,
                p.PaymentStatus as PaymentStatus,
                p.PaymentMethod,
                f.Rating as FeedbackRating,
                f.Comment as FeedbackComments
            FROM Bookings b
            LEFT JOIN Users u ON b.UserID = u.UserID
            LEFT JOIN Venues v ON b.VenueID = v.VenueID
            LEFT JOIN Users vo ON v.OwnerID = vo.UserID
            LEFT JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
            LEFT JOIN Payments p ON b.BookingID = p.BookingID
            LEFT JOIN Feedback f ON f.VenueID = v.VenueID AND f.UserID = b.UserID
            WHERE b.BookingID = ?
        `, [bookingId]);
        
        if (bookings.length === 0) {
            return res.status(404).json({ message: 'Booking not found' });
        }
        
        const booking = bookings[0];
        
        // Check access permissions
        const hasAccess = 
            req.user.roleId === ROLES.ADMIN ||
            booking.UserID === req.user.userId ||
            booking.OwnerID === req.user.userId;
        
        if (!hasAccess) {
            return res.status(403).json({ 
                message: 'Access denied. You can only view your own bookings or bookings at your venues.'
            });
        }
        
        res.json({
            message: 'Booking retrieved successfully',
            booking: booking
        });
        
    } catch (error) {
        console.error('Get booking error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve booking',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// POST /api/bookings/create - Create new venue booking (Player or Admin only)
router.post('/create', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const { VenueID, BookingDate, StartTime, EndTime } = req.body;
        const UserID = req.user.userId;
        
        // Validate required fields
        if (!VenueID || !BookingDate || !StartTime || !EndTime) {
            return res.status(400).json({ message: 'Venue, date, start time, and end time are required' });
        }
        
        // Validate booking date (must be in future)
        const bookingDateTime = new Date(`${BookingDate} ${StartTime}`);
        const now = new Date();
        
        if (bookingDateTime <= now) {
            return res.status(400).json({ message: 'Booking must be for a future date and time' });
        }
        
        // Check if venue exists and get pricing info
        const [venues] = await connection.execute(
            'SELECT VenueID, VenueName, PricePerHour FROM Venues WHERE VenueID = ?',
            [VenueID]
        );
        
        if (venues.length === 0) {
            return res.status(404).json({ message: 'Venue not found' });
        }
        
        // First, check if a timeslot exists for this venue, date, and time
        let [existingTimeslots] = await connection.execute(`
            SELECT TimeslotID, PriceINR, IsAvailable 
            FROM Timeslots 
            WHERE VenueID = ? AND SlotDate = ? AND StartTime = ? AND EndTime = ?
        `, [VenueID, BookingDate, StartTime, EndTime]);
        
        let timeslotId;
        let slotPrice;
        
        if (existingTimeslots.length > 0) {
            const timeslot = existingTimeslots[0];
            if (!timeslot.IsAvailable) {
                return res.status(409).json({ message: 'This time slot is not available' });
            }
            timeslotId = timeslot.TimeslotID;
            slotPrice = timeslot.PriceINR;
        } else {
            // Create a new timeslot
            const venue = venues[0];
            let hourlyRate = venue.PricePerHour || 110; // Use venue pricing or default
            
            // Calculate duration in hours
            const start = new Date(`1970-01-01 ${StartTime}`);
            const end = new Date(`1970-01-01 ${EndTime}`);
            const durationHours = (end - start) / (1000 * 60 * 60);
            slotPrice = hourlyRate * durationHours;
            
            const [timeslotResult] = await connection.execute(`
                INSERT INTO Timeslots (VenueID, SlotDate, StartTime, EndTime, PriceINR, IsAvailable)
                VALUES (?, ?, ?, ?, ?, 1)
            `, [VenueID, BookingDate, StartTime, EndTime, slotPrice]);
            
            timeslotId = timeslotResult.insertId;
        }
        
        // Check for existing bookings for this timeslot
        const [existingBookings] = await connection.execute(`
            SELECT BookingID FROM Bookings 
            WHERE TimeslotID = ? AND BookingStatus IN ('Confirmed', 'Pending')
        `, [timeslotId]);
        
        if (existingBookings.length > 0) {
            return res.status(409).json({ message: 'Time slot already booked' });
        }
        
        // Create the booking
        const [bookingResult] = await connection.execute(`
            INSERT INTO Bookings (UserID, VenueID, TimeslotID, BookingDate, TotalAmount, BookingStatus)
            VALUES (?, ?, ?, ?, ?, 'Pending')
        `, [UserID, VenueID, timeslotId, BookingDate, slotPrice]);
        
        const newBookingId = bookingResult.insertId;
        
        // Create a pending payment record for the booking
        await connection.execute(`
            INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, PaymentDate)
            VALUES (?, ?, 'Cash', 'Pending', CURDATE())
        `, [newBookingId, slotPrice]);
        
        // Mark timeslot as unavailable
        await connection.execute(`
            UPDATE Timeslots SET IsAvailable = 0 WHERE TimeslotID = ?
        `, [timeslotId]);
        
        // Log booking creation
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [UserID, 'CREATE', 'Bookings', newBookingId, null, JSON.stringify({ VenueID, timeslotId, BookingDate, StartTime, EndTime, slotPrice })]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.status(201).json({
            message: 'Booking created successfully',
            booking: {
                id: newBookingId,
                venueId: VenueID,
                timeslotId: timeslotId,
                date: BookingDate,
                startTime: StartTime,
                endTime: EndTime,
                totalAmount: slotPrice,
                status: 'Pending'
            }
        });
        
    } catch (error) {
        console.error('Create booking error:', error);
        res.status(500).json({ 
            message: 'Failed to create booking',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// PUT /api/bookings/update/:id - Update booking (Owner or Admin only)
router.put('/update/:id', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const bookingId = parseInt(req.params.id);
        const { Status, StartTime, EndTime, TeamID } = req.body;
        
        // Get current booking
        const [currentBooking] = await connection.execute(
            'SELECT b.*, v.OwnerID FROM Bookings b LEFT JOIN Venues v ON b.VenueID = v.VenueID WHERE b.BookingID = ?',
            [bookingId]
        );
        
        if (currentBooking.length === 0) {
            return res.status(404).json({ message: 'Booking not found' });
        }
        
        const booking = currentBooking[0];
        
        // Check permissions
        const hasAccess = 
            req.user.roleId === ROLES.ADMIN ||
            booking.UserID === req.user.userId ||
            booking.OwnerID === req.user.userId;
        
        if (!hasAccess) {
            return res.status(403).json({ 
                message: 'Access denied. You can only modify your own bookings or bookings at your venues.'
            });
        }
        
        let updateFields = [];
        let updateValues = [];
        let updatedData = {};
        
        // Only venue owners and admins can change status
        if (Status !== undefined && (req.user.roleId === ROLES.ADMIN || booking.OwnerID === req.user.userId)) {
            if (['Pending', 'Confirmed', 'Cancelled', 'Completed'].includes(Status)) {
                updateFields.push('BookingStatus = ?');
                updateValues.push(Status);
                updatedData.BookingStatus = Status;
            }
        }
        
        // Only booking owner can change times/team (if booking is still pending)
        if (booking.Status === 'Pending' && booking.UserID === req.user.userId) {
            if (StartTime !== undefined) {
                updateFields.push('StartTime = ?');
                updateValues.push(StartTime);
                updatedData.StartTime = StartTime;
            }
            
            if (EndTime !== undefined) {
                updateFields.push('EndTime = ?');
                updateValues.push(EndTime);
                updatedData.EndTime = EndTime;
            }
            
            if (TeamID !== undefined) {
                updateFields.push('TeamID = ?');
                updateValues.push(TeamID);
                updatedData.TeamID = TeamID;
            }
        }
        
        if (updateFields.length === 0) {
            return res.status(400).json({ message: 'No valid fields to update or insufficient permissions' });
        }
        
        updateValues.push(bookingId);
        await connection.execute(
            `UPDATE Bookings SET ${updateFields.join(', ')} WHERE BookingID = ?`,
            updateValues
        );
        
        // Log the update
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'UPDATE', 'Bookings', bookingId, JSON.stringify(booking), JSON.stringify(updatedData)]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Booking updated successfully',
            updatedFields: Object.keys(updatedData)
        });
        
    } catch (error) {
        console.error('Update booking error:', error);
        res.status(500).json({ 
            message: 'Failed to update booking',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// DELETE /api/bookings/delete/:id - Cancel booking (Owner or Admin only)
router.delete('/delete/:id', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const bookingId = parseInt(req.params.id);
        
        // Get booking details
        const [bookingToCancel] = await connection.execute(
            'SELECT b.*, v.OwnerID FROM Bookings b LEFT JOIN Venues v ON b.VenueID = v.VenueID WHERE b.BookingID = ?',
            [bookingId]
        );
        
        if (bookingToCancel.length === 0) {
            return res.status(404).json({ message: 'Booking not found' });
        }
        
        const booking = bookingToCancel[0];
        
        // Check permissions
        const hasAccess = 
            req.user.roleId === ROLES.ADMIN ||
            booking.UserID === req.user.userId ||
            booking.OwnerID === req.user.userId;
        
        if (!hasAccess) {
            return res.status(403).json({ 
                message: 'Access denied. You can only cancel your own bookings or bookings at your venues.'
            });
        }
        
        // Check if booking can be cancelled
        if (booking.Status === 'Completed') {
            return res.status(400).json({ message: 'Cannot cancel completed booking' });
        }
        
        // Instead of deleting, mark as cancelled (better for audit trail)
        await connection.execute(
            'UPDATE Bookings SET BookingStatus = "Cancelled" WHERE BookingID = ?',
            [bookingId]
        );
        
        // Log the cancellation
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'UPDATE', 'Bookings', bookingId, JSON.stringify(booking), JSON.stringify({ Status: 'Cancelled' })]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Booking cancelled successfully',
            booking: {
                id: booking.BookingID,
                venueId: booking.VenueID,
                date: booking.BookingDate,
                status: 'Cancelled'
            }
        });
        
    } catch (error) {
        console.error('Cancel booking error:', error);
        res.status(500).json({ 
            message: 'Failed to cancel booking',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/bookings/venue/:venueId - Get bookings for specific venue (Venue Owner or Admin)
router.get('/venue/:venueId', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const venueId = parseInt(req.params.venueId);
        
        // Check if user owns the venue or is admin
        if (req.user.roleId !== ROLES.ADMIN) {
            const [venueCheck] = await connection.execute(
                'SELECT OwnerID FROM Venues WHERE VenueID = ?',
                [venueId]
            );
            
            if (venueCheck.length === 0) {
                return res.status(404).json({ message: 'Venue not found' });
            }
            
            if (venueCheck[0].OwnerID !== req.user.userId) {
                return res.status(403).json({ message: 'Access denied. You can only view bookings for your own venues.' });
            }
        }
        
        const [bookings] = await connection.execute(`
            SELECT 
                b.BookingID,
                b.BookingDate,
                b.BookingStatus,
                b.TotalAmount,
                ts.StartTime,
                ts.EndTime,
                u.Name as PlayerName,
                u.Email as PlayerEmail,
                u.PhoneNumber as PlayerPhone,
                p.Amount as PaymentAmount,
                p.PaymentStatus as PaymentStatus
            FROM Bookings b
            LEFT JOIN Users u ON b.UserID = u.UserID
            LEFT JOIN Timeslots ts ON b.TimeslotID = ts.TimeslotID
            LEFT JOIN Payments p ON b.BookingID = p.BookingID
            WHERE b.VenueID = ?
            ORDER BY b.BookingDate DESC, ts.StartTime DESC
        `, [venueId]);
        
        res.json({
            message: 'Venue bookings retrieved successfully',
            bookings: bookings,
            total: bookings.length,
            venueId: venueId
        });
        
    } catch (error) {
        console.error('Get venue bookings error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve venue bookings',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// Export router for use in main server application
module.exports = router;
