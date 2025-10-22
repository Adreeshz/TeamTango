const express = require('express');
const router = express.Router();
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const {
    authenticateToken,
    requireAdmin,
    requireAnyRole,
    requireProfileOwnership,
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

// GET all users - Admin only
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const [users] = await connection.execute(`
            SELECT 
                u.UserID, 
                u.Name, 
                u.Email, 
                u.Gender, 
                u.PhoneNumber, 
                u.Address, 
                u.CreatedAt,
                r.RoleName,
                u.RoleID
            FROM Users u 
            LEFT JOIN Roles r ON u.RoleID = r.RoleID 
            ORDER BY u.CreatedAt DESC
        `);
        
        // Add user type for each user
        const usersWithType = users.map(user => ({
            ...user,
            userType: user.RoleID === 1 ? 'player' : user.RoleID === 2 ? 'venue_owner' : user.RoleID === 3 ? 'admin' : 'unknown'
        }));
        
        res.json({
            message: 'Users retrieved successfully',
            users: usersWithType,
            total: usersWithType.length
        });
        
    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve users',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET search players - Authenticated players only (search across Users fields)
// NOTE: This must come BEFORE the /:id route to avoid conflicts
router.get('/search', authenticateToken, async (req, res) => {
    let connection;
    try {
        console.log('Search request received');
        console.log('User:', req.user);
        console.log('Query:', req.query);
        
        // Only allow players (RoleID = 1) or admins to perform this search
        if (req.user.roleId !== ROLES.PLAYER && req.user.roleId !== ROLES.ADMIN) {
            console.log('Access denied for user role:', req.user.roleId);
            return res.status(403).json({ message: 'Access denied. Only players or admins can search players.' });
        }

        const q = (req.query.q || '').trim();
        console.log('Search term:', q);
        connection = await createConnection();

        // Build WHERE clause - always restrict to players (RoleID = 1)
        let whereClause = 'u.RoleID = 1';
        const params = [];

        if (q.length > 0) {
            const like = `%${q}%`;
            whereClause += ` AND (CAST(u.UserID AS CHAR) LIKE ? OR u.Name LIKE ? OR u.Email LIKE ? OR u.Gender LIKE ? OR u.PhoneNumber LIKE ? OR u.Address LIKE ? OR DATE_FORMAT(u.CreatedAt, '%Y-%m-%d %H:%i:%s') LIKE ?)`;
            // push same parameter for each LIKE
            params.push(like, like, like, like, like, like, like);
        }

        // Limit results to a reasonable number
        const sql = `
            SELECT 
                u.UserID,
                u.Name,
                u.Email,
                u.Gender,
                u.PhoneNumber,
                u.Address,
                u.CreatedAt,
                r.RoleName,
                u.RoleID
            FROM Users u
            LEFT JOIN Roles r ON u.RoleID = r.RoleID
            WHERE ${whereClause}
            ORDER BY u.CreatedAt DESC
            LIMIT 100
        `;

        const [users] = await connection.execute(sql, params);
        console.log('Raw query results:', users.length, 'users found');

        const usersWithType = users.map(user => ({
            ...user,
            userType: user.RoleID === 1 ? 'player' : user.RoleID === 2 ? 'venue_owner' : user.RoleID === 3 ? 'admin' : 'unknown'
        }));

        console.log('Sending response with', usersWithType.length, 'users');
        res.json({
            message: 'Players retrieved successfully',
            users: usersWithType,
            total: usersWithType.length
        });

    } catch (error) {
        console.error('Search users error:', error);
        res.status(500).json({ message: 'Failed to search users', error: error.message });
    } finally {
        if (connection) await connection.end();
    }
});

// GET user by ID - Own profile or Admin only
router.get('/:id', authenticateToken, requireProfileOwnership, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const [users] = await connection.execute(`
            SELECT 
                u.UserID, 
                u.Name, 
                u.Email, 
                u.Gender, 
                u.PhoneNumber, 
                u.Address, 
                u.CreatedAt,
                r.RoleName,
                u.RoleID
            FROM Users u 
            LEFT JOIN Roles r ON u.RoleID = r.RoleID 
            WHERE u.UserID = ?
        `, [req.params.id]);
        
        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const user = users[0];
        user.userType = user.RoleID === 1 ? 'player' : user.RoleID === 2 ? 'venue_owner' : user.RoleID === 3 ? 'admin' : 'unknown';
        
        res.json({
            message: 'User retrieved successfully',
            user: user
        });
        
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve user',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// POST create user - Admin only (for manual user creation)
router.post('/create', authenticateToken, requireAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const { Name, Email, Gender, Password, PhoneNumber, Address, userType } = req.body;
        
        // Validate required fields
        if (!Name || !Email || !Password || !PhoneNumber || !userType) {
            return res.status(400).json({ message: 'All required fields must be provided' });
        }
        
        // Validate user type
        if (!['player', 'venue_owner', 'admin'].includes(userType)) {
            return res.status(400).json({ message: 'Invalid user type' });
        }
        
        // Check if email already exists
        const [existingUsers] = await connection.execute(
            'SELECT UserID FROM Users WHERE Email = ?',
            [Email]
        );
        
        if (existingUsers.length > 0) {
            return res.status(409).json({ message: 'Email already registered' });
        }
        
        // Hash password
        const hashedPassword = await bcrypt.hash(Password, 10);
        
        // Determine role ID
        const roleId = userType === 'player' ? 1 : userType === 'venue_owner' ? 2 : 3;
        
        // Insert new user
        const [result] = await connection.execute(
            'INSERT INTO Users (Name, Email, Gender, Password, PhoneNumber, Address, RoleID) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [Name, Email, Gender, hashedPassword, PhoneNumber, Address, roleId]
        );
        
        const newUserId = result.insertId;
        
        // Log user creation
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'CREATE', 'Users', newUserId, null, JSON.stringify({ Name, Email, userType })]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.status(201).json({
            message: 'User created successfully',
            user: {
                id: newUserId,
                name: Name,
                email: Email,
                phone: PhoneNumber,
                userType: userType,
                role: userType === 'player' ? 'Player' : userType === 'venue_owner' ? 'Venue Owner' : 'Admin'
            }
        });
        
    } catch (error) {
        console.error('Create user error:', error);
        res.status(500).json({ 
            message: 'Failed to create user',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// PUT update user - Own profile or Admin can edit any user
router.put('/update/:id', authenticateToken, async (req, res) => {
    // Check if user is admin or editing their own profile
    const targetUserId = parseInt(req.params.id);
    if (req.user.roleId !== 3 && req.user.userId !== targetUserId) {
        return res.status(403).json({ 
            message: 'Access denied. You can only edit your own profile unless you are an admin.',
            error: 'INSUFFICIENT_PERMISSION'
        });
    }
    let connection;
    try {
        connection = await createConnection();
        
        const { Name, Email, Gender, PhoneNumber, Address, userType, RoleID } = req.body;
        const userId = parseInt(req.params.id);
        
        // Get current user data for audit log
        const [currentUser] = await connection.execute(
            'SELECT * FROM Users WHERE UserID = ?',
            [userId]
        );
        
        if (currentUser.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        let updateFields = [];
        let updateValues = [];
        let updatedData = {};
        
        // Build dynamic update query
        if (Name !== undefined) {
            updateFields.push('Name = ?');
            updateValues.push(Name);
            updatedData.Name = Name;
        }
        
        if (Email !== undefined) {
            // Check if email is already taken by another user
            const [emailCheck] = await connection.execute(
                'SELECT UserID FROM Users WHERE Email = ? AND UserID != ?',
                [Email, userId]
            );
            
            if (emailCheck.length > 0) {
                return res.status(409).json({ message: 'Email already taken by another user' });
            }
            
            updateFields.push('Email = ?');
            updateValues.push(Email);
            updatedData.Email = Email;
        }
        
        if (Gender !== undefined) {
            updateFields.push('Gender = ?');
            updateValues.push(Gender);
            updatedData.Gender = Gender;
        }
        
        if (PhoneNumber !== undefined) {
            updateFields.push('PhoneNumber = ?');
            updateValues.push(PhoneNumber);
            updatedData.PhoneNumber = PhoneNumber;
        }
        
        if (Address !== undefined) {
            updateFields.push('Address = ?');
            updateValues.push(Address);
            updatedData.Address = Address;
        }
        
        // Only admins can change user type/role
        if (RoleID !== undefined && req.user.roleId === ROLES.ADMIN) {
            if ([1, 2, 3].includes(parseInt(RoleID))) {
                updateFields.push('RoleID = ?');
                updateValues.push(parseInt(RoleID));
                updatedData.RoleID = parseInt(RoleID);
            }
        } else if (userType !== undefined && req.user.roleId === ROLES.ADMIN) {
            if (['player', 'venue_owner', 'admin'].includes(userType)) {
                const roleId = userType === 'player' ? 1 : userType === 'venue_owner' ? 2 : 3;
                updateFields.push('RoleID = ?');
                updateValues.push(roleId);
                updatedData.userType = userType;
            }
        }
        
        if (updateFields.length === 0) {
            return res.status(400).json({ message: 'No valid fields to update' });
        }
        
        // Perform update
        updateValues.push(userId);
        await connection.execute(
            `UPDATE Users SET ${updateFields.join(', ')} WHERE UserID = ?`,
            updateValues
        );
        
        // Log the update
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'UPDATE', 'Users', userId, JSON.stringify(currentUser[0]), JSON.stringify(updatedData)]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'User updated successfully',
            updatedFields: Object.keys(updatedData)
        });
        
    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({ 
            message: 'Failed to update user',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// DELETE user - Admin only
router.delete('/delete/:id', authenticateToken, requireAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const userId = parseInt(req.params.id);
        
        // Get user data before deletion for audit log
        const [userToDelete] = await connection.execute(
            'SELECT * FROM Users WHERE UserID = ?',
            [userId]
        );
        
        if (userToDelete.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Prevent self-deletion
        if (userId === req.user.userId) {
            return res.status(400).json({ message: 'Cannot delete your own account' });
        }
        
        // Delete user (this will cascade to related records based on foreign key constraints)
        await connection.execute('DELETE FROM Users WHERE UserID = ?', [userId]);
        
        // Log the deletion
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'DELETE', 'Users', userId, JSON.stringify(userToDelete[0]), null]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'User deleted successfully',
            deletedUser: {
                id: userToDelete[0].UserID,
                name: userToDelete[0].Name,
                email: userToDelete[0].Email
            }
        });
        
    } catch (error) {
        console.error('Delete user error:', error);
        res.status(500).json({ 
            message: 'Failed to delete user',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET users by role - Admin only
router.get('/role/:roleName', authenticateToken, requireAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const roleName = req.params.roleName.toLowerCase();
        let roleId;
        
        switch (roleName) {
            case 'player':
                roleId = 1;
                break;
            case 'venue_owner':
                roleId = 2;
                break;
            case 'admin':
                roleId = 3;
                break;
            default:
                return res.status(400).json({ message: 'Invalid role name' });
        }
        
        const [users] = await connection.execute(`
            SELECT 
                u.UserID, 
                u.Name, 
                u.Email, 
                u.Gender, 
                u.PhoneNumber, 
                u.Address, 
                u.CreatedAt,
                r.RoleName
            FROM Users u 
            LEFT JOIN Roles r ON u.RoleID = r.RoleID 
            WHERE u.RoleID = ?
            ORDER BY u.CreatedAt DESC
        `, [roleId]);
        
        res.json({
            message: `${roleName}s retrieved successfully`,
            users: users,
            total: users.length,
            role: roleName
        });
        
    } catch (error) {
        console.error('Get users by role error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve users by role',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

module.exports = router;
