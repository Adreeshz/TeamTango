const express = require('express');
const router = express.Router();
const mysql = require('mysql2/promise');
const {
    authenticateToken,
    requireAdmin,
    requirePlayerOrAdmin,
    requireVenueOwnerOrAdmin,
    requireAnyRole,
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

// GET /api/payments - Get payments (Role-based access)
// - Players: See only their own payments
// - Venue Owners: See payments for their venues
// - Admin: See all payments
router.get('/', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        let query = `
            SELECT 
                p.PaymentID,
                p.BookingID,
                p.Amount,
                p.PaymentMethod,
                p.PaymentStatus as Status,
                p.PaymentDate as TransactionDate,
                p.PaymentDate as CreatedAt,
                b.BookingDate,
                t.StartTime,
                t.EndTime,
                b.UserID as PayerID,
                u.Name as PayerName,
                v.VenueName,
                v.OwnerID as VenueOwnerID
            FROM Payments p
            LEFT JOIN Bookings b ON p.BookingID = b.BookingID
            LEFT JOIN Users u ON b.UserID = u.UserID
            LEFT JOIN Venues v ON b.VenueID = v.VenueID
            LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
        `;
        
        let whereConditions = [];
        let queryParams = [];
        
        // Apply role-based filtering
        if (req.user.roleId === ROLES.PLAYER) {
            whereConditions.push('b.UserID = ?');
            queryParams.push(req.user.userId);
        } else if (req.user.roleId === ROLES.VENUE_OWNER) {
            whereConditions.push('v.OwnerID = ?');
            queryParams.push(req.user.userId);
        }
        // Admin sees all payments (no additional filtering)
        
        if (whereConditions.length > 0) {
            query += ' WHERE ' + whereConditions.join(' AND ');
        }
        
        query += ' ORDER BY p.PaymentDate DESC';
        
        const [payments] = await connection.execute(query, queryParams);
        
        res.json({
            message: 'Payments retrieved successfully',
            payments: payments,
            total: payments.length
        });
        
    } catch (error) {
        console.error('Get payments error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve payments',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/payments/my - Get current user's payments (Player only)
router.get('/my', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        let userId = req.user.userId;
        
        // For admin, allow fetching any user's payments
        if (req.user.roleId === ROLES.ADMIN && req.query.userId) {
            userId = parseInt(req.query.userId);
        }
        
        const [payments] = await connection.execute(`
            SELECT 
                p.PaymentID,
                p.BookingID,
                p.Amount,
                p.PaymentMethod,
                p.PaymentStatus as Status,
                p.PaymentDate as TransactionDate,
                p.PaymentDate as CreatedAt,
                b.BookingDate,
                t.StartTime,
                t.EndTime,
                v.VenueName,
                v.Location as VenueAddress
            FROM Payments p
            LEFT JOIN Bookings b ON p.BookingID = b.BookingID
            LEFT JOIN Venues v ON b.VenueID = v.VenueID
            LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
            WHERE b.UserID = ?
            ORDER BY p.PaymentDate DESC
        `, [userId]);
        
        res.json({
            message: 'Your payments retrieved successfully',
            payments: payments,
            total: payments.length
        });
        
    } catch (error) {
        console.error('Get my payments error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve your payments',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/payments/:id - Get payment by ID (Owner or Admin only)
router.get('/:id', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const paymentId = parseInt(req.params.id);
        
        const [payments] = await connection.execute(`
            SELECT 
                p.*,
                b.BookingDate,
                t.StartTime,
                t.EndTime,
                b.UserID as PayerID,
                u.Name as PayerName,
                u.Email as PayerEmail,
                v.VenueName,
                v.Location as VenueAddress,
                v.OwnerID as VenueOwnerID,
                vo.Name as VenueOwnerName
            FROM Payments p
            LEFT JOIN Bookings b ON p.BookingID = b.BookingID
            LEFT JOIN Users u ON b.UserID = u.UserID
            LEFT JOIN Venues v ON b.VenueID = v.VenueID
            LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
            LEFT JOIN Users vo ON v.OwnerID = vo.UserID
            WHERE p.PaymentID = ?
        `, [paymentId]);
        
        if (payments.length === 0) {
            return res.status(404).json({ message: 'Payment not found' });
        }
        
        const payment = payments[0];
        
        // Check access permissions
        const hasAccess = 
            req.user.roleId === ROLES.ADMIN ||
            payment.PayerID === req.user.userId ||
            payment.VenueOwnerID === req.user.userId;
        
        if (!hasAccess) {
            return res.status(403).json({ 
                message: 'Access denied. You can only view your own payments or payments for your venues.'
            });
        }
        
        res.json({
            message: 'Payment retrieved successfully',
            payment: payment
        });
        
    } catch (error) {
        console.error('Get payment error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve payment',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// POST /api/payments/process - Process payment for booking (Player or Admin only)
router.post('/process', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const { BookingID, PaymentMethod, Amount } = req.body;
        const userId = req.user.userId;
        
        // Validate required fields
        if (!BookingID || !PaymentMethod || !Amount) {
            return res.status(400).json({ message: 'Booking ID, payment method, and amount are required' });
        }
        
        // Check if booking exists and belongs to user (unless admin)
        const [bookings] = await connection.execute(`
            SELECT 
                b.BookingID,
                b.UserID,
                b.BookingStatus,
                v.VenueName
            FROM Bookings b
            LEFT JOIN Venues v ON b.VenueID = v.VenueID
            WHERE b.BookingID = ?
        `, [BookingID]);
        
        if (bookings.length === 0) {
            return res.status(404).json({ message: 'Booking not found' });
        }
        
        const booking = bookings[0];
        
        // Check if user owns the booking (unless admin)
        if (req.user.roleId !== ROLES.ADMIN && booking.UserID !== userId) {
            return res.status(403).json({ message: 'You can only make payments for your own bookings' });
        }
        
        // Check if booking is in a payable state
        if (!['Pending', 'Confirmed'].includes(booking.BookingStatus)) {
            return res.status(400).json({ message: 'Cannot make payment for this booking status' });
        }
        
        // Check if payment already exists for this booking
        const [existingPayments] = await connection.execute(
            'SELECT PaymentID FROM Payments WHERE BookingID = ?',
            [BookingID]
        );
        
        if (existingPayments.length > 0) {
            return res.status(409).json({ message: 'Payment already exists for this booking' });
        }
        
        // Process payment using stored procedure (if available)
        try {
            const [result] = await connection.execute(
                'CALL ProcessPayment(?, ?, ?)',
                [BookingID, Amount, PaymentMethod]
            );
            
            const newPaymentId = result[0][0].PaymentID;
            
            res.status(201).json({
                message: 'Payment processed successfully',
                payment: {
                    id: newPaymentId,
                    bookingId: BookingID,
                    amount: Amount,
                    method: PaymentMethod,
                    status: 'Completed'
                }
            });
            
        } catch (procError) {
            // Fallback to manual payment processing
            console.log('Stored procedure not available, using manual processing:', procError.message);
            
            // Begin transaction
            await connection.beginTransaction();
            
            try {
                // Create payment record
                const [paymentResult] = await connection.execute(
                    'INSERT INTO Payments (BookingID, Amount, PaymentMethod, PaymentStatus, PaymentDate) VALUES (?, ?, ?, ?, NOW())',
                    [BookingID, Amount, PaymentMethod, 'Success']
                );
                
                const newPaymentId = paymentResult.insertId;
                
                // Update booking status to confirmed
                await connection.execute(
                    'UPDATE Bookings SET BookingStatus = "Confirmed" WHERE BookingID = ?',
                    [BookingID]
                );
                
                // Commit transaction
                await connection.commit();
                
                // Log payment creation
                try {
                    await connection.execute(
                        'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                        [userId, 'CREATE', 'Payments', newPaymentId, null, JSON.stringify({ BookingID, Amount, PaymentMethod, Status: 'Completed' })]
                    );
                } catch (logError) {
                    console.log('Audit logging failed:', logError.message);
                }
                
                res.status(201).json({
                    message: 'Payment processed successfully',
                    payment: {
                        id: newPaymentId,
                        bookingId: BookingID,
                        amount: Amount,
                        method: PaymentMethod,
                        status: 'Completed'
                    }
                });
                
            } catch (processError) {
                await connection.rollback();
                throw processError;
            }
        }
        
    } catch (error) {
        console.error('Process payment error:', error);
        res.status(500).json({ 
            message: 'Failed to process payment',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// PUT /api/payments/update/:id - Update payment status (Admin only)
router.put('/update/:id', authenticateToken, requireAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const paymentId = parseInt(req.params.id);
        const { Status, PaymentMethod } = req.body;
        
        // Get current payment data for audit log
        const [currentPayment] = await connection.execute(
            'SELECT * FROM Payments WHERE PaymentID = ?',
            [paymentId]
        );
        
        if (currentPayment.length === 0) {
            return res.status(404).json({ message: 'Payment not found' });
        }
        
        let updateFields = [];
        let updateValues = [];
        let updatedData = {};
        
        if (Status !== undefined) {
            if (['Pending', 'Success', 'Failed', 'Refunded'].includes(Status)) {
                updateFields.push('PaymentStatus = ?');
                updateValues.push(Status);
                updatedData.PaymentStatus = Status;
            }
        }
        
        if (PaymentMethod !== undefined) {
            updateFields.push('PaymentMethod = ?');
            updateValues.push(PaymentMethod);
            updatedData.PaymentMethod = PaymentMethod;
        }
        
        if (updateFields.length === 0) {
            return res.status(400).json({ message: 'No valid fields to update' });
        }
        
        updateValues.push(paymentId);
        await connection.execute(
            `UPDATE Payments SET ${updateFields.join(', ')} WHERE PaymentID = ?`,
            updateValues
        );
        
        // Log the update
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'UPDATE', 'Payments', paymentId, JSON.stringify(currentPayment[0]), JSON.stringify(updatedData)]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Payment updated successfully',
            updatedFields: Object.keys(updatedData)
        });
        
    } catch (error) {
        console.error('Update payment error:', error);
        res.status(500).json({ 
            message: 'Failed to update payment',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// POST /api/payments/refund/:id - Process refund (Admin only)
router.post('/refund/:id', authenticateToken, requireAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const paymentId = parseInt(req.params.id);
        const { reason } = req.body;
        
        // Get payment details
        const [payments] = await connection.execute(`
            SELECT 
                p.*,
                b.BookingID,
                b.BookingStatus
            FROM Payments p
            LEFT JOIN Bookings b ON p.BookingID = b.BookingID
            WHERE p.PaymentID = ?
        `, [paymentId]);
        
        if (payments.length === 0) {
            return res.status(404).json({ message: 'Payment not found' });
        }
        
        const payment = payments[0];
        
        if (payment.Status !== 'Completed') {
            return res.status(400).json({ message: 'Can only refund completed payments' });
        }
        
        // Begin transaction
        await connection.beginTransaction();
        
        try {
            // Update payment status to refunded
            await connection.execute(
                'UPDATE Payments SET PaymentStatus = "Refunded" WHERE PaymentID = ?',
                [paymentId]
            );
            
            // Update booking status to cancelled
            await connection.execute(
                'UPDATE Bookings SET BookingStatus = "Cancelled" WHERE BookingID = ?',
                [payment.BookingID]
            );
            
            // Commit transaction
            await connection.commit();
            
            // Log the refund
            try {
                await connection.execute(
                    'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                    [req.user.userId, 'UPDATE', 'Payments', paymentId, JSON.stringify(payment), JSON.stringify({ Status: 'Refunded', RefundReason: reason })]
                );
            } catch (logError) {
                console.log('Audit logging failed:', logError.message);
            }
            
            res.json({
                message: 'Refund processed successfully',
                payment: {
                    id: paymentId,
                    originalAmount: payment.Amount,
                    status: 'Refunded',
                    reason: reason
                }
            });
            
        } catch (refundError) {
            await connection.rollback();
            throw refundError;
        }
        
    } catch (error) {
        console.error('Process refund error:', error);
        res.status(500).json({ 
            message: 'Failed to process refund',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/payments/venue/:venueId - Get payments for specific venue (Venue Owner or Admin)
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
                return res.status(403).json({ message: 'Access denied. You can only view payments for your own venues.' });
            }
        }
        
        const [payments] = await connection.execute(`
            SELECT 
                p.*,
                b.BookingDate,
                t.StartTime,
                t.EndTime,
                u.Name as PayerName,
                u.Email as PayerEmail
            FROM Payments p
            LEFT JOIN Bookings b ON p.BookingID = b.BookingID
            LEFT JOIN Users u ON b.UserID = u.UserID
            LEFT JOIN Timeslots t ON b.TimeslotID = t.TimeslotID
            WHERE b.VenueID = ?
            ORDER BY p.PaymentDate DESC
        `, [venueId]);
        
        const totalRevenue = payments
            .filter(p => p.Status === 'Success')
            .reduce((sum, p) => sum + parseFloat(p.Amount), 0);
        
        res.json({
            message: 'Venue payments retrieved successfully',
            payments: payments,
            total: payments.length,
            totalRevenue: totalRevenue,
            venueId: venueId
        });
        
    } catch (error) {
        console.error('Get venue payments error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve venue payments',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

module.exports = router;
