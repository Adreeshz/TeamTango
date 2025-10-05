const express = require('express');
const router = express.Router();
const db = require('../utils/db');
const { checkPermission, requireAdmin, logActivity, getUserPermissions } = require('../utils/permissions');

// GET all users (only admins can see all users)
router.get('/', requireAdmin, logActivity('SELECT', 'Users'), (req, res) => {
    db.query('SELECT UserID, Name, Email, Gender, PhoneNumber, Address, RoleID, CreatedAt FROM Users', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json({
            users: results,
            message: 'Users retrieved successfully',
            requestedBy: req.userClassification
        });
    });
});

// GET user by ID (users can view their own profile, admins can view any)
router.get('/:id', async (req, res) => {
    try {
        const requestedUserID = req.params.id;
        const currentUserID = req.headers['user-id'] || req.query.userId;
        
        if (!currentUserID) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        
        // Allow users to view their own profile or admins to view any profile
        const userClassification = await require('../utils/permissions').PermissionManager.getUserClassification(currentUserID);
        
        if (currentUserID !== requestedUserID && userClassification?.UserType !== 'Admin User') {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'You can only view your own profile'
            });
        }
        
        db.query('SELECT UserID, Name, Email, Gender, PhoneNumber, Address, RoleID, CreatedAt FROM Users WHERE UserID=?', [requestedUserID], (err, results) => {
            if(err) return res.status(500).json({ error: err });
            if(results.length === 0) return res.status(404).json({ error: 'User not found' });
            res.json({
                user: results[0],
                message: 'User profile retrieved successfully'
            });
        });
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to retrieve user' });
    }
});

// POST create user (anyone can register, but role is determined by the system)
router.post('/create', logActivity('INSERT', 'Users'), (req, res) => {
    const { Name, Email, Gender, Password, PhoneNumber, Address, UserType = 'player' } = req.body;
    
    // Validate required fields
    if (!Name || !Email || !Password) {
        return res.status(400).json({ 
            error: 'Missing required fields', 
            required: ['Name', 'Email', 'Password']
        });
    }
    
    // Determine RoleID based on UserType
    let RoleID = 1; // Default to player
    switch (UserType.toLowerCase()) {
        case 'player':
            RoleID = 1;
            break;
        case 'venue_owner':
            RoleID = 2;
            break;
        case 'admin':
            RoleID = 3; // Only allow through special admin registration
            break;
        default:
            RoleID = 1;
    }
    
    // Check if email already exists
    db.query('SELECT UserID FROM Users WHERE Email = ?', [Email], (err, existing) => {
        if (err) return res.status(500).json({ error: err });
        if (existing.length > 0) {
            return res.status(409).json({ error: 'Email already registered' });
        }
        
        // Insert new user
        db.query(
            'INSERT INTO Users (Name, Email, Gender, Password, PhoneNumber, Address, RoleID) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [Name, Email, Gender, Password, PhoneNumber, Address, RoleID],
            (err, result) => {
                if(err) return res.status(500).json({ error: err });
                
                // Get the created user with role info
                db.query(`
                    SELECT u.UserID, u.Name, u.Email, r.RoleName, u.CreatedAt
                    FROM Users u 
                    JOIN Roles r ON u.RoleID = r.RoleID 
                    WHERE u.UserID = ?
                `, [result.insertId], (err, userResult) => {
                    if (err) return res.status(500).json({ error: err });
                    
                    res.status(201).json({ 
                        message: 'User created successfully', 
                        user: userResult[0],
                        userType: UserType,
                        note: 'User can now login and access features based on their role'
                    });
                });
            }
        );
    });
});

// PUT update user (users can update own profile, admins can update any)
router.put('/update/:id', async (req, res) => {
    try {
        const targetUserID = req.params.id;
        const currentUserID = req.headers['user-id'] || req.query.userId;
        const { Name, Email, Gender, PhoneNumber, Address } = req.body;
        
        if (!currentUserID) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        
        // Check if user can update this profile
        const userClassification = await require('../utils/permissions').PermissionManager.getUserClassification(currentUserID);
        
        if (currentUserID !== targetUserID && userClassification?.UserType !== 'Admin User') {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'You can only update your own profile'
            });
        }
        
        // Validate email uniqueness if email is being changed
        if (Email) {
            const emailCheck = await new Promise((resolve, reject) => {
                db.query('SELECT UserID FROM Users WHERE Email = ? AND UserID != ?', [Email, targetUserID], (err, results) => {
                    if (err) reject(err);
                    else resolve(results);
                });
            });
            
            if (emailCheck.length > 0) {
                return res.status(409).json({ error: 'Email already in use by another user' });
            }
        }
        
        // Build update query dynamically
        const updates = [];
        const values = [];
        
        if (Name) { updates.push('Name = ?'); values.push(Name); }
        if (Email) { updates.push('Email = ?'); values.push(Email); }
        if (Gender) { updates.push('Gender = ?'); values.push(Gender); }
        if (PhoneNumber) { updates.push('PhoneNumber = ?'); values.push(PhoneNumber); }
        if (Address) { updates.push('Address = ?'); values.push(Address); }
        
        if (updates.length === 0) {
            return res.status(400).json({ error: 'No valid fields to update' });
        }
        
        values.push(targetUserID);
        
        db.query(
            `UPDATE Users SET ${updates.join(', ')} WHERE UserID = ?`,
            values,
            (err, result) => {
                if(err) return res.status(500).json({ error: err });
                if(result.affectedRows === 0) return res.status(404).json({ error: 'User not found' });
                
                // Log the activity
                require('../utils/permissions').PermissionManager.logActivity(
                    currentUserID, 'UPDATE', 'Users', targetUserID, 
                    `Profile updated for user ${targetUserID}`
                );
                
                res.json({ 
                    message: 'Profile updated successfully',
                    updatedFields: updates.length
                });
            }
        );
    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
});

// DELETE user (only super admin can delete users)
router.delete('/delete/:id', async (req, res) => {
    try {
        const targetUserID = req.params.id;
        const currentUserID = req.headers['user-id'] || req.query.userId;
        
        if (!currentUserID) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        
        // Only super admin (RoleID = 4) can delete users
        const userClassification = await require('../utils/permissions').PermissionManager.getUserClassification(currentUserID);
        
        if (!userClassification || userClassification.RoleID !== 4) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only super admin can delete users'
            });
        }
        
        // Prevent super admin from deleting themselves
        if (currentUserID === targetUserID) {
            return res.status(400).json({ 
                error: 'Cannot delete own account',
                message: 'Super admin cannot delete their own account'
            });
        }
        
        db.query('DELETE FROM Users WHERE UserID=?', [targetUserID], (err, result) => {
            if(err) return res.status(500).json({ error: err });
            if(result.affectedRows === 0) return res.status(404).json({ error: 'User not found' });
            
            // Log the deletion
            require('../utils/permissions').PermissionManager.logActivity(
                currentUserID, 'DELETE', 'Users', targetUserID, 
                `User account deleted by super admin`
            );
            
            res.json({ 
                message: 'User deleted successfully',
                deletedBy: userClassification.Name
            });
        });
    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({ error: 'Failed to delete user' });
    }
});

// GET user permissions (users can see their own permissions, admins can see any)
router.get('/:id/permissions', getUserPermissions);

// POST promote user to admin (only super admin)
router.post('/promote/:id', async (req, res) => {
    try {
        const targetUserID = req.params.id;
        const currentUserID = req.headers['user-id'] || req.query.userId;
        
        if (!currentUserID) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        
        // Only super admin can promote users
        const userClassification = await require('../utils/permissions').PermissionManager.getUserClassification(currentUserID);
        
        if (!userClassification || userClassification.RoleID !== 4) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only super admin can promote users'
            });
        }
        
        // Call stored procedure to promote user
        db.query('CALL PromoteUserToAdmin(?, ?)', [currentUserID, targetUserID], (err, result) => {
            if(err) return res.status(500).json({ error: err });
            
            res.json({ 
                message: 'User promoted to admin successfully',
                promotedBy: userClassification.Name,
                result: result[0][0]
            });
        });
    } catch (error) {
        console.error('Promote user error:', error);
        res.status(500).json({ error: 'Failed to promote user' });
    }
});

// GET user activity log (admins only)
router.get('/:id/activity', requireAdmin, (req, res) => {
    const userID = req.params.id;
    
    db.query(`
        SELECT 
            LogID, Action, TableName, RecordID, ActionDetails, 
            IPAddress, CreatedAt
        FROM UserActivityLog 
        WHERE UserID = ? 
        ORDER BY CreatedAt DESC 
        LIMIT 50
    `, [userID], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        
        res.json({
            userID: userID,
            activities: results,
            message: 'User activity log retrieved successfully'
        });
    });
});

module.exports = router;