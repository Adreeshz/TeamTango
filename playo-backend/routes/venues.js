// Import required modules for venue management
const express = require('express');        // Web framework for creating routes
const router = express.Router();          // Create router instance for venue endpoints
const mysql = require('mysql2/promise');   // MySQL database driver with promise support
const {
    authenticateToken,
    requireAdmin,
    requireVenueOwner,
    requireVenueOwnerOrAdmin,
    requireAnyRole,
    requireVenueOwnership,
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

// GET /api/venues/search - Search venues by all fields (Public access)
router.get('/search', async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const { q } = req.query;
        
        if (!q || q.trim().length === 0) {
            return res.status(400).json({ message: 'Search query is required' });
        }
        
        const searchTerm = `%${q.trim()}%`;
        
        // Search across all venue fields
        // Use venue_summary view for simplified query with pre-computed stats
        const [venues] = await connection.execute(`
            SELECT 
                VenueID, 
                VenueName, 
                Location, 
                OwnerID,
                OwnerName,
                OwnerPhone,
                COALESCE(SportName, 'Multi-Sport') as SportType,
                PricePerHour,
                CASE                                                    
                    WHEN VenueName LIKE '%Shiv Chhatrapati%' THEN 'Modern indoor courts with professional lighting and air conditioning'
                    WHEN VenueName LIKE '%Cooperage%' THEN 'Full-size field with natural grass and floodlights'
                    WHEN VenueName LIKE '%Deccan%' THEN 'Premium courts with synthetic surface and coaching facilities'
                    WHEN VenueName LIKE '%Sanas%' THEN 'Air-conditioned courts with wooden flooring'
                    WHEN VenueName LIKE '%MCA%' THEN 'Professional ground with turf wicket and practice nets'
                    ELSE 'Well-maintained sports facility with modern amenities'    
                END as Description,
                COALESCE(AverageRating, 4.5) as Rating,
                TotalBookings,
                TotalReviews,
                AvailableSlots
            FROM venue_summary
            WHERE VenueName LIKE ? 
               OR Location LIKE ? 
               OR OwnerName LIKE ? 
               OR OwnerPhone LIKE ?
               OR CAST(VenueID AS CHAR) LIKE ?
               OR CAST(PricePerHour AS CHAR) LIKE ?
               OR SportName LIKE ?
            ORDER BY VenueName
        `, [searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm]);
        
        // Post-process results to add local image paths for each venue
        const venuesWithImages = venues.map((venue, index) => {
            let imagePath = 'images/';
            
            // Smart image mapping based on venue names and sport types
            if (venue.VenueName.includes('Shiv Chhatrapati')) {
                imagePath += 'coep.jpg';
            } else if (venue.VenueName.includes('Deccan')) {
                imagePath += 'deccan.jpg';
            } else if (venue.VenueName.includes('Sanas')) {
                imagePath += 'badminton.png';
            } else if (venue.SportType === 'Basketball') {
                imagePath += 'basketball.jpg';
            } else if (venue.SportType === 'Football') {
                imagePath += 'football.jpg';
            } else if (venue.SportType === 'Tennis') {
                imagePath += 'tennis.jpg';
            } else if (venue.SportType === 'Badminton') {
                imagePath += 'badminton.png';
            } else if (venue.SportType === 'Cricket') {
                imagePath += 'cricket.jpg';
            } else if (venue.SportType === 'Volleyball') {
                imagePath += 'volleyball.jpg';
            } else {
                imagePath += 'basketball.jpg';
            }
            
            return {
                ...venue,
                Image: imagePath
            };
        });
        
        res.json({
            message: 'Venue search completed successfully',
            venues: venuesWithImages,
            total: venuesWithImages.length,
            searchQuery: q
        });
        
    } catch (error) {
        console.error('Venue search error:', error);
        res.status(500).json({ 
            message: 'Failed to search venues',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/venues - Fetch all venues (Public access for viewing)
// This endpoint provides comprehensive venue data with dynamic pricing and descriptions
router.get('/', async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        // Use venue_summary view for pre-aggregated venue data
        const [venues] = await connection.execute(`
            SELECT 
                VenueID, 
                VenueName, 
                Location, 
                OwnerID,
                OwnerName,
                COALESCE(SportName, 'Multi-Sport') as SportType,
                PricePerHour,
                COALESCE(AverageRating, 4.5) as Rating,
                TotalBookings,
                TotalReviews,
                AvailableSlots,
                CASE                                                    
                    WHEN v.VenueName LIKE '%Shiv Chhatrapati%' THEN 'Modern indoor courts with professional lighting and air conditioning'
                    WHEN v.VenueName LIKE '%Cooperage%' THEN 'Full-size field with natural grass and floodlights'
                    WHEN v.VenueName LIKE '%Deccan%' THEN 'Premium courts with synthetic surface and coaching facilities'
                    WHEN v.VenueName LIKE '%Sanas%' THEN 'Air-conditioned courts with wooden flooring'
                    WHEN v.VenueName LIKE '%MCA%' THEN 'Professional ground with turf wicket and practice nets'
                    ELSE 'Well-maintained sports facility with modern amenities'    
                END as Description
            FROM venue_summary
            ORDER BY VenueName
        `);
        
        // Post-process results to add local image paths for each venue
        const venuesWithImages = venues.map((venue, index) => {
            let imagePath = 'images/';
            
            // Smart image mapping based on venue names and sport types
            if (venue.VenueName.includes('Shiv Chhatrapati')) {
                imagePath += 'coep.jpg';
            } else if (venue.VenueName.includes('Deccan')) {
                imagePath += 'deccan.jpg';
            } else if (venue.VenueName.includes('Sanas')) {
                imagePath += 'badminton.png';
            } else if (venue.SportType === 'Basketball') {
                imagePath += 'basketball.jpg';
            } else if (venue.SportType === 'Football') {
                imagePath += 'football.jpg';
            } else if (venue.SportType === 'Tennis') {
                imagePath += 'tennis.jpg';
            } else if (venue.SportType === 'Badminton') {
                imagePath += 'badminton.png';
            } else if (venue.SportType === 'Cricket') {
                imagePath += 'cricket.jpg';
            } else if (venue.SportType === 'Volleyball') {
                imagePath += 'volleyball.jpg';
            } else {
                imagePath += 'basketball.jpg';
            }
            
            return {
                ...venue,
                Image: imagePath
            };
        });
        
        res.json({
            message: 'Venues retrieved successfully',
            venues: venuesWithImages,
            total: venuesWithImages.length
        });
        
    } catch (error) {
        console.error('Get venues error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve venues',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/venues/my - Get venues owned by current user (Venue Owner only)
router.get('/my', authenticateToken, requireVenueOwnerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        let whereClause = '';
        let queryParams = [];
        
        if (req.user.roleId === ROLES.VENUE_OWNER) {
            whereClause = 'WHERE v.OwnerID = ?';
            queryParams.push(req.user.userId);
        }
        
        const [venues] = await connection.execute(`
            SELECT 
                v.VenueID, 
                v.VenueName, 
                v.Address, 
                v.Location,
                v.ContactNumber,
                v.PricePerHour,
                v.City,
                v.OwnerID,
                u.Name as OwnerName,
                (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID) as TotalBookings,
                (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID AND b.BookingStatus = 'Confirmed') as ConfirmedBookings,
                (SELECT COALESCE(SUM(p.Amount), 0) FROM Payments p JOIN Bookings b ON p.BookingID = b.BookingID WHERE b.VenueID = v.VenueID AND p.PaymentStatus = 'Success') as TotalRevenue
            FROM Venues v 
            LEFT JOIN Users u ON v.OwnerID = u.UserID
            ${whereClause}
            ORDER BY v.VenueID DESC
        `, queryParams);
        
        res.json({
            message: 'Your venues retrieved successfully',
            venues: venues,
            total: venues.length
        });
        
    } catch (error) {
        console.error('Get my venues error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve your venues',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/venues/revenue - Get revenue summary for venue owner's venues
router.get('/revenue', authenticateToken, requireVenueOwnerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        let whereClause = '';
        let queryParams = [];
        
        if (req.user.roleId === ROLES.VENUE_OWNER) {
            whereClause = 'WHERE OwnerID = ?';
            queryParams.push(req.user.userId);
        }
        
        // Use venue_revenue view for pre-aggregated revenue data
        const [revenueData] = await connection.execute(`
            SELECT 
                OwnerID,
                OwnerName,
                VenueID,
                VenueName,
                TotalBookings,
                ConfirmedBookings,
                PendingBookings,
                TotalRevenue,
                MonthlyRevenue
            FROM venue_revenue
            ${whereClause}
            ORDER BY TotalRevenue DESC
        `, queryParams);
        
        // Calculate totals
        const totals = revenueData.reduce((acc, venue) => ({
            totalBookings: acc.totalBookings + venue.TotalBookings,
            confirmedBookings: acc.confirmedBookings + venue.ConfirmedBookings,
            totalRevenue: acc.totalRevenue + parseFloat(venue.TotalRevenue || 0),
            monthlyRevenue: acc.monthlyRevenue + parseFloat(venue.MonthlyRevenue || 0)
        }), { totalBookings: 0, confirmedBookings: 0, totalRevenue: 0, monthlyRevenue: 0 });
        
        res.json({
            message: 'Revenue data retrieved successfully',
            venues: revenueData,
            totals: totals,
            total: revenueData.length
        });
        
    } catch (error) {
        console.error('Get revenue error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve revenue data',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/venues/:id - Fetch single venue by ID (Owner or Admin only for detailed info)
router.get('/:id', authenticateToken, requireVenueOwnerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const venueId = parseInt(req.params.id);
        
        // Check ownership for venue owners (admins can access any venue)
        let whereClause = 'WHERE v.VenueID = ?';
        let queryParams = [venueId];
        
        if (req.user.roleId === ROLES.VENUE_OWNER) {
            whereClause = 'WHERE v.VenueID = ? AND v.OwnerID = ?';
            queryParams = [venueId, req.user.userId];
        }
        
        const [venues] = await connection.execute(`
            SELECT 
                v.VenueID, 
                v.VenueName, 
                v.Address, 
                v.Location,
                v.ContactNumber,
                v.PricePerHour,
                v.City,
                v.OwnerID,
                u.Name as OwnerName,
                u.Email as OwnerEmail,
                u.PhoneNumber as OwnerPhone,
                (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID) as TotalBookings,
                (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID AND b.BookingStatus = 'Confirmed') as ConfirmedBookings,
                (SELECT AVG(f.Rating) FROM Feedback f WHERE f.VenueID = v.VenueID) as AverageRating
            FROM Venues v 
            LEFT JOIN Users u ON v.OwnerID = u.UserID
            ${whereClause}
        `, queryParams);
        
        if (venues.length === 0) {
            return res.status(404).json({ message: 'Venue not found or access denied' });
        }
        
        res.json({
            message: 'Venue retrieved successfully',
            venue: venues[0]
        });
        
    } catch (error) {
        console.error('Get venue error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve venue',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// POST /api/venues/create - Create new venue (Venue Owner or Admin only)
router.post('/create', authenticateToken, requireVenueOwnerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const { VenueName, Address } = req.body;
        
        // Validate required fields
        if (!VenueName || !Address) {
            return res.status(400).json({ message: 'Venue name and address are required' });
        }
        
        // For venue owners, use their own ID as owner. For admins, allow specifying owner
        let OwnerID = req.user.userId;
        if (req.user.roleId === ROLES.ADMIN && req.body.OwnerID) {
            OwnerID = req.body.OwnerID;
        }
        
        // Check if venue name already exists at the same address
        const [existingVenues] = await connection.execute(
            'SELECT VenueID FROM Venues WHERE VenueName = ? AND Address = ?',
            [VenueName, Address]
        );
        
        if (existingVenues.length > 0) {
            return res.status(409).json({ message: 'A venue with this name already exists at this address' });
        }
        
        // Insert new venue (use Address for both Location and Address fields)
        const [result] = await connection.execute(
            'INSERT INTO Venues (VenueName, Location, Address, OwnerID, ContactNumber, PricePerHour) VALUES (?, ?, ?, ?, ?, ?)',
            [VenueName, Address, Address, OwnerID, '0000000000', 0.00]
        );
        
        const newVenueId = result.insertId;
        
        // Log venue creation
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'CREATE', 'Venues', newVenueId, null, JSON.stringify({ VenueName, Address, OwnerID })]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.status(201).json({
            message: 'Venue created successfully',
            venue: {
                id: newVenueId,
                name: VenueName,
                address: Address,
                ownerId: OwnerID
            }
        });
        
    } catch (error) {
        console.error('Create venue error:', error);
        res.status(500).json({ 
            message: 'Failed to create venue',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// PUT /api/venues/:id - Update existing venue (Owner or Admin only)
router.put('/:id', authenticateToken, requireVenueOwnerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const venueId = parseInt(req.params.id);
        
        // Check ownership for venue owners (admins can edit any venue)
        if (req.user.roleId === ROLES.VENUE_OWNER) {
            const [ownershipCheck] = await connection.execute(
                'SELECT VenueID FROM Venues WHERE VenueID = ? AND OwnerID = ?',
                [venueId, req.user.userId]
            );
            
            if (ownershipCheck.length === 0) {
                return res.status(403).json({ message: 'You can only edit your own venues' });
            }
        }
        
        const { VenueName, Address, ContactNumber, PricePerHour, City } = req.body;
        
        // Get current venue data for audit log
        const [currentVenue] = await connection.execute(
            'SELECT * FROM Venues WHERE VenueID = ?',
            [venueId]
        );
        
        if (currentVenue.length === 0) {
            return res.status(404).json({ message: 'Venue not found' });
        }
        
        let updateFields = [];
        let updateValues = [];
        let updatedData = {};
        
        if (VenueName !== undefined && VenueName.trim() !== '') {
            updateFields.push('VenueName = ?');
            updateValues.push(VenueName.trim());
            updatedData.VenueName = VenueName.trim();
        }
        
        if (Address !== undefined && Address.trim() !== '') {
            updateFields.push('Address = ?');
            updateFields.push('Location = ?');
            updateValues.push(Address.trim());
            updateValues.push(Address.trim());
            updatedData.Address = Address.trim();
            updatedData.Location = Address.trim();
        }
        
        if (ContactNumber !== undefined && ContactNumber.trim() !== '') {
            updateFields.push('ContactNumber = ?');
            updateValues.push(ContactNumber.trim());
            updatedData.ContactNumber = ContactNumber.trim();
        }
        
        if (PricePerHour !== undefined && PricePerHour !== null) {
            const price = parseFloat(PricePerHour);
            if (!isNaN(price) && price >= 0) {
                updateFields.push('PricePerHour = ?');
                updateValues.push(price);
                updatedData.PricePerHour = price;
            }
        }
        
        if (City !== undefined && City.trim() !== '') {
            updateFields.push('City = ?');
            updateValues.push(City.trim());
            updatedData.City = City.trim();
        }
        
        if (updateFields.length === 0) {
            return res.status(400).json({ message: 'No valid fields to update' });
        }
        
        updateValues.push(venueId);
        await connection.execute(
            `UPDATE Venues SET ${updateFields.join(', ')} WHERE VenueID = ?`,
            updateValues
        );
        
        // Log the update
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'UPDATE', 'Venues', venueId, JSON.stringify(currentVenue[0]), JSON.stringify(updatedData)]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Venue updated successfully',
            updatedFields: Object.keys(updatedData),
            venue: { VenueID: venueId, ...updatedData }
        });
        
    } catch (error) {
        console.error('Update venue error:', error);
        res.status(500).json({ 
            message: 'Failed to update venue',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// PUT /api/venues/update/:id - Update existing venue (Owner or Admin only) - Legacy endpoint
router.put('/update/:id', authenticateToken, requireVenueOwnerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const venueId = parseInt(req.params.id);
        const { VenueName, Address } = req.body;
        
        // Get current venue data for audit log
        const [currentVenue] = await connection.execute(
            'SELECT * FROM Venues WHERE VenueID = ?',
            [venueId]
        );
        
        if (currentVenue.length === 0) {
            return res.status(404).json({ message: 'Venue not found' });
        }
        
        let updateFields = [];
        let updateValues = [];
        let updatedData = {};
        
        if (VenueName !== undefined) {
            updateFields.push('VenueName = ?');
            updateValues.push(VenueName);
            updatedData.VenueName = VenueName;
        }
        
        if (Address !== undefined) {
            updateFields.push('Address = ?');
            updateValues.push(Address);
            updatedData.Address = Address;
        }
        
        if (updateFields.length === 0) {
            return res.status(400).json({ message: 'No valid fields to update' });
        }
        
        updateValues.push(venueId);
        await connection.execute(
            `UPDATE Venues SET ${updateFields.join(', ')} WHERE VenueID = ?`,
            updateValues
        );
        
        // Log the update
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'UPDATE', 'Venues', venueId, JSON.stringify(currentVenue[0]), JSON.stringify(updatedData)]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Venue updated successfully',
            updatedFields: Object.keys(updatedData)
        });
        
    } catch (error) {
        console.error('Update venue error:', error);
        res.status(500).json({ 
            message: 'Failed to update venue',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// DELETE /api/venues/delete/:venueId - Remove venue from platform (Owner or Admin only)
router.delete('/delete/:venueId', authenticateToken, requireVenueOwnership, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const venueId = parseInt(req.params.venueId);
        
        // Get venue data before deletion for audit log
        const [venueToDelete] = await connection.execute(
            'SELECT * FROM Venues WHERE VenueID = ?',
            [venueId]
        );
        
        if (venueToDelete.length === 0) {
            return res.status(404).json({ message: 'Venue not found' });
        }
        
        // Check for active bookings
        const [activeBookings] = await connection.execute(
            'SELECT COUNT(*) as count FROM Bookings WHERE VenueID = ? AND BookingStatus IN ("Confirmed", "Pending")',
            [venueId]
        );
        
        if (activeBookings[0].count > 0) {
            return res.status(400).json({ 
                message: 'Cannot delete venue with active bookings. Please cancel or complete all bookings first.',
                activeBookings: activeBookings[0].count
            });
        }
        
        // Delete venue (this will cascade to related records based on foreign key constraints)
        await connection.execute('DELETE FROM Venues WHERE VenueID = ?', [venueId]);
        
        // Log the deletion
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'DELETE', 'Venues', venueId, JSON.stringify(venueToDelete[0]), null]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Venue deleted successfully',
            deletedVenue: {
                id: venueToDelete[0].VenueID,
                name: venueToDelete[0].VenueName,
                address: venueToDelete[0].Address
            }
        });
        
    } catch (error) {
        console.error('Delete venue error:', error);
        res.status(500).json({ 
            message: 'Failed to delete venue',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/venues/:id/bookings - Get bookings for a specific venue (Owner or Admin only)
router.get('/:id/bookings', authenticateToken, requireVenueOwnership, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const venueId = parseInt(req.params.id);
        
        const [bookings] = await connection.execute(`
            SELECT 
                b.BookingID,
                b.BookingDate,
                ts.StartTime,
                ts.EndTime,
                b.BookingStatus,
                u.Name as PlayerName,
                u.Email as PlayerEmail,
                u.PhoneNumber as PlayerPhone,
                b.TotalAmount,
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
