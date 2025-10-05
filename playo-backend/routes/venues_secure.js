const express = require('express');
const router = express.Router();
const db = require('../utils/db');
const { checkPermission, logActivity, PermissionManager } = require('../utils/permissions');

// GET all venues (everyone can view venues)
router.get('/', checkPermission('Venues', 'SELECT'), logActivity('SELECT', 'Venues'), (req, res) => {
    const { city = 'Pune', sport } = req.query;
    
    let query = `
        SELECT v.*, s.SportName, u.Name as OwnerName, u.PhoneNumber as OwnerPhone
        FROM Venues v
        LEFT JOIN Sports s ON v.SportID = s.SportID
        LEFT JOIN Users u ON v.OwnerID = u.UserID
        WHERE v.City = ?
    `;
    const params = [city];
    
    if (sport) {
        query += ` AND s.SportName LIKE ?`;
        params.push(`%${sport}%`);
    }
    
    query += ` ORDER BY v.CreatedAt DESC`;
    
    db.query(query, params, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json({
            venues: results,
            city: city,
            sport: sport || 'All sports',
            total: results.length,
            message: 'Venues retrieved successfully'
        });
    });
});

// GET venue by ID with available timeslots
router.get('/:id', checkPermission('Venues', 'SELECT'), (req, res) => {
    const venueID = req.params.id;
    
    db.query(`
        SELECT v.*, s.SportName, u.Name as OwnerName, u.PhoneNumber as OwnerPhone, u.Email as OwnerEmail
        FROM Venues v
        LEFT JOIN Sports s ON v.SportID = s.SportID
        LEFT JOIN Users u ON v.OwnerID = u.UserID
        WHERE v.VenueID = ?
    `, [venueID], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        if(results.length === 0) return res.status(404).json({ error: 'Venue not found' });
        
        // Get available timeslots
        db.query(`
            SELECT ts.*, 
                   CASE WHEN b.BookingID IS NOT NULL THEN 'Booked' ELSE 'Available' END as Status
            FROM Timeslots ts
            LEFT JOIN Bookings b ON ts.SlotID = b.SlotID AND b.BookingDate >= CURDATE()
            WHERE ts.VenueID = ?
            ORDER BY ts.StartTime
        `, [venueID], (err, timeslots) => {
            if(err) return res.status(500).json({ error: err });
            
            res.json({
                venue: results[0],
                timeslots: timeslots,
                message: 'Venue details retrieved successfully'
            });
        });
    });
});

// POST create venue (only venue owners can create venues)
router.post('/create', checkPermission('Venues', 'INSERT'), logActivity('INSERT', 'Venues'), async (req, res) => {
    try {
        const { VenueName, Address, City = 'Pune', SportID, PricePerHour, Description, Facilities } = req.body;
        const currentUserID = req.userID;
        
        if (!VenueName || !Address || !SportID || !PricePerHour) {
            return res.status(400).json({ 
                error: 'Missing required fields', 
                required: ['VenueName', 'Address', 'SportID', 'PricePerHour']
            });
        }
        
        // Check if user is a venue owner (RoleID = 2)
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        if (userClassification.RoleID !== 2) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only venue owners can create venues'
            });
        }
        
        // Check if venue name already exists in the same city
        db.query('SELECT VenueID FROM Venues WHERE VenueName = ? AND City = ?', 
            [VenueName, City], (err, existing) => {
            if (err) return res.status(500).json({ error: err });
            if (existing.length > 0) {
                return res.status(409).json({ 
                    error: 'Venue name already exists in this city' 
                });
            }
            
            // Create the venue
            db.query(
                'INSERT INTO Venues (VenueName, Address, City, SportID, OwnerID, PricePerHour, Description, Facilities) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [VenueName, Address, City, SportID, currentUserID, PricePerHour, Description, Facilities],
                (err, result) => {
                    if(err) return res.status(500).json({ error: err });
                    
                    res.status(201).json({ 
                        message: 'Venue created successfully', 
                        VenueID: result.insertId,
                        VenueName: VenueName,
                        City: City,
                        note: 'You can now add timeslots for this venue'
                    });
                }
            );
        });
    } catch (error) {
        console.error('Create venue error:', error);
        res.status(500).json({ error: 'Failed to create venue' });
    }
});

// PUT update venue (only venue owner or admins can update)
router.put('/update/:id', checkPermission('Venues', 'UPDATE'), logActivity('UPDATE', 'Venues'), async (req, res) => {
    try {
        const venueID = req.params.id;
        const currentUserID = req.userID;
        const { VenueName, Address, City, PricePerHour, Description, Facilities } = req.body;
        
        // Check if user owns this venue or is admin
        const venueResult = await new Promise((resolve, reject) => {
            db.query('SELECT OwnerID, VenueName FROM Venues WHERE VenueID = ?', [venueID], (err, results) => {
                if (err) reject(err);
                else resolve(results);
            });
        });
        
        if (venueResult.length === 0) {
            return res.status(404).json({ error: 'Venue not found' });
        }
        
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        const isVenueOwner = venueResult[0].OwnerID == currentUserID;
        const isAdmin = userClassification?.UserType === 'Admin User';
        
        if (!isVenueOwner && !isAdmin) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only venue owner or admins can update venue details'
            });
        }
        
        // Build update query
        const updates = [];
        const values = [];
        
        if (VenueName) { updates.push('VenueName = ?'); values.push(VenueName); }
        if (Address) { updates.push('Address = ?'); values.push(Address); }
        if (City) { updates.push('City = ?'); values.push(City); }
        if (PricePerHour) { updates.push('PricePerHour = ?'); values.push(PricePerHour); }
        if (Description) { updates.push('Description = ?'); values.push(Description); }
        if (Facilities) { updates.push('Facilities = ?'); values.push(Facilities); }
        
        if (updates.length === 0) {
            return res.status(400).json({ error: 'No valid fields to update' });
        }
        
        values.push(venueID);
        
        db.query(
            `UPDATE Venues SET ${updates.join(', ')} WHERE VenueID = ?`,
            values,
            (err, result) => {
                if(err) return res.status(500).json({ error: err });
                
                res.json({ 
                    message: 'Venue updated successfully',
                    venueName: venueResult[0].VenueName,
                    updatedBy: isVenueOwner ? 'Venue Owner' : 'Admin',
                    updatedFields: updates.length
                });
            }
        );
    } catch (error) {
        console.error('Update venue error:', error);
        res.status(500).json({ error: 'Failed to update venue' });
    }
});

// DELETE venue (only admins can delete venues)
router.delete('/delete/:id', async (req, res) => {
    try {
        const venueID = req.params.id;
        const currentUserID = req.userID || req.headers['user-id'] || req.query.userId;
        
        if (!currentUserID) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        
        // Only admins can delete venues
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        if (userClassification?.UserType !== 'Admin User') {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only admins can delete venues'
            });
        }
        
        // Check if venue has active bookings
        const activeBookings = await new Promise((resolve, reject) => {
            db.query(`
                SELECT COUNT(*) as activeCount 
                FROM Bookings b 
                JOIN Timeslots ts ON b.SlotID = ts.SlotID 
                WHERE ts.VenueID = ? AND b.BookingDate >= CURDATE()
            `, [venueID], (err, results) => {
                if (err) reject(err);
                else resolve(results[0].activeCount);
            });
        });
        
        if (activeBookings > 0) {
            return res.status(400).json({ 
                error: 'Cannot delete venue', 
                message: 'Venue has active bookings. Please resolve these first.',
                activeBookings: activeBookings
            });
        }
        
        // Get venue name for logging
        const venueName = await new Promise((resolve, reject) => {
            db.query('SELECT VenueName FROM Venues WHERE VenueID = ?', [venueID], (err, results) => {
                if (err) reject(err);
                else resolve(results[0]?.VenueName || 'Unknown');
            });
        });
        
        // Delete timeslots first (foreign key constraint)
        db.query('DELETE FROM Timeslots WHERE VenueID = ?', [venueID], (err) => {
            if (err) return res.status(500).json({ error: 'Failed to remove timeslots' });
            
            // Delete the venue
            db.query('DELETE FROM Venues WHERE VenueID = ?', [venueID], (err, result) => {
                if(err) return res.status(500).json({ error: err });
                if(result.affectedRows === 0) return res.status(404).json({ error: 'Venue not found' });
                
                // Log the deletion
                PermissionManager.logActivity(
                    currentUserID, 'DELETE', 'Venues', venueID, 
                    `Venue '${venueName}' deleted by admin`
                );
                
                res.json({ 
                    message: 'Venue deleted successfully',
                    venueName: venueName,
                    deletedBy: userClassification.Name
                });
            });
        });
    } catch (error) {
        console.error('Delete venue error:', error);
        res.status(500).json({ error: 'Failed to delete venue' });
    }
});

// GET venues owned by user (for venue owners to see their venues)
router.get('/owner/:userID', checkPermission('Venues', 'SELECT'), async (req, res) => {
    try {
        const ownerID = req.params.userID;
        const currentUserID = req.userID || req.headers['user-id'] || req.query.userId;
        
        // Allow users to see their own venues or admins to see any user's venues
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        
        if (currentUserID !== ownerID && userClassification?.UserType !== 'Admin User') {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'You can only view your own venues'
            });
        }
        
        db.query(`
            SELECT v.*, s.SportName, 
                   COUNT(DISTINCT ts.SlotID) as TotalSlots,
                   COUNT(DISTINCT b.BookingID) as TotalBookings,
                   SUM(CASE WHEN b.BookingDate >= CURDATE() THEN 1 ELSE 0 END) as ActiveBookings
            FROM Venues v
            LEFT JOIN Sports s ON v.SportID = s.SportID
            LEFT JOIN Timeslots ts ON v.VenueID = ts.VenueID
            LEFT JOIN Bookings b ON ts.SlotID = b.SlotID
            WHERE v.OwnerID = ?
            GROUP BY v.VenueID
            ORDER BY v.CreatedAt DESC
        `, [ownerID], (err, results) => {
            if(err) return res.status(500).json({ error: err });
            
            res.json({
                ownerID: ownerID,
                venues: results,
                total: results.length,
                message: 'Owner venues retrieved successfully'
            });
        });
    } catch (error) {
        console.error('Get owner venues error:', error);
        res.status(500).json({ error: 'Failed to get owner venues' });
    }
});

// POST add timeslot to venue (only venue owner can add timeslots)
router.post('/:id/timeslots', checkPermission('Timeslots', 'INSERT'), async (req, res) => {
    try {
        const venueID = req.params.id;
        const currentUserID = req.userID;
        const { StartTime, EndTime, PricePerSlot } = req.body;
        
        if (!StartTime || !EndTime) {
            return res.status(400).json({ 
                error: 'Missing required fields', 
                required: ['StartTime', 'EndTime']
            });
        }
        
        // Check if user owns this venue
        const venueResult = await new Promise((resolve, reject) => {
            db.query('SELECT OwnerID, VenueName FROM Venues WHERE VenueID = ?', [venueID], (err, results) => {
                if (err) reject(err);
                else resolve(results);
            });
        });
        
        if (venueResult.length === 0) {
            return res.status(404).json({ error: 'Venue not found' });
        }
        
        if (venueResult[0].OwnerID != currentUserID) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only venue owner can add timeslots'
            });
        }
        
        // Check for conflicting timeslots
        db.query(`
            SELECT SlotID FROM Timeslots 
            WHERE VenueID = ? AND (
                (StartTime <= ? AND EndTime > ?) OR
                (StartTime < ? AND EndTime >= ?) OR
                (StartTime >= ? AND EndTime <= ?)
            )
        `, [venueID, StartTime, StartTime, EndTime, EndTime, StartTime, EndTime], (err, conflicts) => {
            if (err) return res.status(500).json({ error: err });
            if (conflicts.length > 0) {
                return res.status(409).json({ 
                    error: 'Time conflict', 
                    message: 'This timeslot conflicts with existing slots'
                });
            }
            
            // Add the timeslot
            db.query(
                'INSERT INTO Timeslots (VenueID, StartTime, EndTime, PricePerSlot) VALUES (?, ?, ?, ?)',
                [venueID, StartTime, EndTime, PricePerSlot],
                (err, result) => {
                    if(err) return res.status(500).json({ error: err });
                    
                    // Log the activity
                    PermissionManager.logActivity(
                        currentUserID, 'INSERT', 'Timeslots', result.insertId, 
                        `Added timeslot ${StartTime}-${EndTime} to venue ${venueResult[0].VenueName}`
                    );
                    
                    res.status(201).json({ 
                        message: 'Timeslot added successfully',
                        slotID: result.insertId,
                        venueName: venueResult[0].VenueName,
                        timeSlot: `${StartTime} - ${EndTime}`
                    });
                }
            );
        });
    } catch (error) {
        console.error('Add timeslot error:', error);
        res.status(500).json({ error: 'Failed to add timeslot' });
    }
});

module.exports = router;