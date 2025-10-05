const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'teamtango_pune_secret_key_2025';

// Database config
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '1234',
    database: 'dbms_cp'
};

// Create database connection
async function createConnection() {
    return await mysql.createConnection(dbConfig);
}

// Register new user
router.post('/register', async (req, res) => {
    const connection = await createConnection();
    
    try {
        const { name, email, gender, password, phoneNumber, address, userType } = req.body;
        
        // Validate input
        if (!name || !email || !password || !phoneNumber || !userType) {
            return res.status(400).json({ message: 'All required fields must be provided' });
        }
        
        if (!['player', 'venue_owner'].includes(userType)) {
            return res.status(400).json({ message: 'Invalid user type. Must be player or venue_owner' });
        }
        
        // Check if email already exists
        const [existingUsers] = await connection.execute(
            'SELECT UserID FROM Users WHERE Email = ?',
            [email]
        );
        
        if (existingUsers.length > 0) {
            return res.status(409).json({ message: 'Email already registered. Please use a different email or try logging in.' });
        }
        
        // Hash password
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        
        // Determine RoleID based on userType
        const roleId = userType === 'player' ? 1 : 2;
        
        // Insert new user using stored procedure (if available) or direct insert
        try {
            // Try using the stored procedure first
            const [result] = await connection.execute(
                'CALL CreateUserWithRole(?, ?, ?, ?, ?, ?, ?)',
                [name, email, gender, hashedPassword, phoneNumber, address, userType]
            );
            
            const newUserId = result[0].UserID;
            
            // Get the complete user info
            const [userInfo] = await connection.execute(
                'SELECT u.UserID, u.Name, u.Email, u.PhoneNumber, r.RoleName FROM Users u JOIN Roles r ON u.RoleID = r.RoleID WHERE u.UserID = ?',
                [newUserId]
            );
            
            res.status(201).json({
                message: 'User registered successfully!',
                user: {
                    id: userInfo[0].UserID,
                    name: userInfo[0].Name,
                    email: userInfo[0].Email,
                    phone: userInfo[0].PhoneNumber,
                    role: userInfo[0].RoleName,
                    userType: userType
                }
            });
            
        } catch (procError) {
            // If stored procedure fails, use direct insert
            console.log('Stored procedure not available, using direct insert:', procError.message);
            
            const [insertResult] = await connection.execute(
                'INSERT INTO Users (Name, Email, Gender, Password, PhoneNumber, Address, RoleID) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [name, email, gender, hashedPassword, phoneNumber, address, roleId]
            );
            
            const newUserId = insertResult.insertId;
            
            // Log user creation in activity log (if table exists)
            try {
                await connection.execute(
                    'INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails) VALUES (?, ?, ?, ?, ?)',
                    [newUserId, 'CREATE', 'Users', newUserId, `New user created with role: ${userType}`]
                );
            } catch (logError) {
                console.log('Activity logging not available:', logError.message);
            }
            
            // Get role name for response
            const roleName = userType === 'player' ? 'Player' : 'Venue Owner';
            
            res.status(201).json({
                message: 'User registered successfully!',
                user: {
                    id: newUserId,
                    name: name,
                    email: email,
                    phone: phoneNumber,
                    role: roleName,
                    userType: userType
                }
            });
        }
        
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ 
            message: 'Registration failed. Please try again.',
            error: error.message 
        });
    } finally {
        await connection.end();
    }
});

// Login user
router.post('/login', async (req, res) => {
    console.log('🔐 Login attempt for:', req.body.email);
    
    let connection;
    try {
        connection = await createConnection();
        console.log('✅ Database connection established');
        
        const { email, password } = req.body;
        
        // Validate input
        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password are required' });
        }
        
        // Get user with role information
        const [users] = await connection.execute(
            'SELECT u.UserID, u.Name, u.Email, u.Password, u.PhoneNumber, u.RoleID, r.RoleName FROM Users u LEFT JOIN Roles r ON u.RoleID = r.RoleID WHERE u.Email = ?',
            [email]
        );
        
        if (users.length === 0) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }
        
        const user = users[0];
        
        // Verify password
        const isPasswordValid = await bcrypt.compare(password, user.Password);
        
        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }
        
        // Generate JWT token
        const token = jwt.sign(
            { 
                userId: user.UserID, 
                email: user.Email, 
                roleId: user.RoleID,
                roleName: user.RoleName 
            },
            JWT_SECRET,
            { expiresIn: '24h' }
        );
        
        // Log successful login
        try {
            await connection.execute(
                'INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails) VALUES (?, ?, ?, ?, ?)',
                [user.UserID, 'LOGIN', 'Users', user.UserID, 'User logged in successfully']
            );
        } catch (logError) {
            console.log('Activity logging not available:', logError.message);
        }
        
        // Determine user type
        const userType = user.RoleID === 1 ? 'player' : user.RoleID === 2 ? 'venue_owner' : 'unknown';
        
        res.json({
            message: 'Login successful',
            token: token,
            user: {
                id: user.UserID,
                name: user.Name,
                email: user.Email,
                phone: user.PhoneNumber,
                role: user.RoleName || 'Unknown',
                userType: userType,
                roleId: user.RoleID
            }
        });
        
    } catch (error) {
        console.error('❌ Login error:', error);
        res.status(500).json({ 
            message: 'Login failed. Please try again.',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// Get user profile
router.get('/profile', authenticateToken, async (req, res) => {
    const connection = await createConnection();
    
    try {
        const [users] = await connection.execute(
            'SELECT u.UserID, u.Name, u.Email, u.PhoneNumber, u.Gender, u.Address, u.CreatedAt, r.RoleName FROM Users u LEFT JOIN Roles r ON u.RoleID = r.RoleID WHERE u.UserID = ?',
            [req.user.userId]
        );
        
        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const user = users[0];
        const userType = user.RoleID === 1 ? 'player' : user.RoleID === 2 ? 'venue_owner' : 'unknown';
        
        res.json({
            user: {
                id: user.UserID,
                name: user.Name,
                email: user.Email,
                phone: user.PhoneNumber,
                gender: user.Gender,
                address: user.Address,
                role: user.RoleName,
                userType: userType,
                createdAt: user.CreatedAt
            }
        });
        
    } catch (error) {
        console.error('Profile fetch error:', error);
        res.status(500).json({ message: 'Failed to fetch profile' });
    } finally {
        await connection.end();
    }
});

// Update user profile
router.put('/profile', authenticateToken, async (req, res) => {
    const connection = await createConnection();
    
    try {
        const { name, phoneNumber, address, gender } = req.body;
        const userId = req.user.userId;
        
        // Update user profile
        await connection.execute(
            'UPDATE Users SET Name = ?, PhoneNumber = ?, Address = ?, Gender = ? WHERE UserID = ?',
            [name, phoneNumber, address, gender, userId]
        );
        
        // Log profile update
        try {
            await connection.execute(
                'INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails) VALUES (?, ?, ?, ?, ?)',
                [userId, 'UPDATE', 'Users', userId, 'Profile updated']
            );
        } catch (logError) {
            console.log('Activity logging not available:', logError.message);
        }
        
        res.json({ message: 'Profile updated successfully' });
        
    } catch (error) {
        console.error('Profile update error:', error);
        res.status(500).json({ message: 'Failed to update profile' });
    } finally {
        await connection.end();
    }
});

// Check user permissions
router.get('/permissions/:tableName/:action', authenticateToken, async (req, res) => {
    const connection = await createConnection();
    
    try {
        const { tableName, action } = req.params;
        const userId = req.user.userId;
        
        // Try using stored procedure first
        try {
            const [result] = await connection.execute(
                'CALL CheckUserPermission(?, ?, ?)',
                [userId, tableName, action.toUpperCase()]
            );
            
            res.json({
                hasPermission: result[0][0].HasPermission === 1,
                userRole: result[0][0].UserRole
            });
        } catch (procError) {
            // Fallback to manual permission check
            const [permissions] = await connection.execute(
                `SELECT up.Can${action.charAt(0).toUpperCase() + action.slice(1).toLowerCase()} as HasPermission, u.RoleID 
                 FROM Users u 
                 LEFT JOIN UserPermissions up ON u.RoleID = up.RoleID AND up.TableName = ?
                 WHERE u.UserID = ?`,
                [tableName, userId]
            );
            
            res.json({
                hasPermission: permissions.length > 0 ? permissions[0].HasPermission === 1 : false,
                userRole: permissions.length > 0 ? permissions[0].RoleID : null
            });
        }
        
    } catch (error) {
        console.error('Permission check error:', error);
        res.status(500).json({ message: 'Failed to check permissions' });
    } finally {
        await connection.end();
    }
});

// Middleware to authenticate JWT token
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
    
    if (!token) {
        return res.status(401).json({ message: 'Access token required' });
    }
    
    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ message: 'Invalid or expired token' });
        }
        req.user = user;
        next();
    });
}

module.exports = router;