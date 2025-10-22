// Import required modules for authentication functionality
const express = require('express');        // Web framework for creating routes
const bcrypt = require('bcrypt');          // Password hashing library for security
const jwt = require('jsonwebtoken');       // JSON Web Token library for authentication
const mysql = require('mysql2/promise');   // MySQL database driver with promise support

// Create router instance for authentication endpoints
const router = express.Router();
// JWT secret key for signing tokens (uses environment variable or fallback)
const JWT_SECRET = process.env.JWT_SECRET || 'teamtango_pune_secret_key_2025';

// Database configuration object for MySQL connection
const dbConfig = {
    host: 'localhost',          // MySQL server hostname
    user: 'root',              // Database username
    password: '1234',          // Database password
    database: 'dbms_cp'        // Target database name
};

// Helper function to create a new database connection
// Returns a promise-based connection for async/await usage
async function createConnection() {
    return await mysql.createConnection(dbConfig);
}

// POST /api/auth/register - Register new user account
// Handles user registration with validation, password hashing, and database insertion
router.post('/register', async (req, res) => {
    // Create new database connection for this request
    const connection = await createConnection();
    
    try {
        // Extract user registration data from request body
        const { name, email, gender, password, phoneNumber, address, userType } = req.body;
        
        // Validate required input fields to ensure data completeness
        if (!name || !email || !password || !phoneNumber || !userType) {
            return res.status(400).json({ message: 'All required fields must be provided' });
        }
        
        // Validate user type to ensure only allowed roles can register
        // Note: Admin accounts cannot be created through public registration for security
        if (!['player', 'venue_owner'].includes(userType)) {
            return res.status(400).json({ message: 'Invalid user type. Must be player or venue_owner' });
        }
        
        // Check if email already exists in database to prevent duplicates
        const [existingUsers] = await connection.execute(
            'SELECT UserID FROM Users WHERE Email = ?', // Query to find existing email
            [email]                                     // Parameter binding for security
        );
        
        // Return conflict error if email is already registered
        if (existingUsers.length > 0) {
            return res.status(409).json({ message: 'Email already registered. Please use a different email or try logging in.' });
        }
        
        // Hash password using bcrypt for secure storage
        const saltRounds = 10;                           // Salt rounds for bcrypt (higher = more secure but slower)
        const hashedPassword = await bcrypt.hash(password, saltRounds); // Generate salted hash
        
        // Determine database role ID based on user type selection
        const roleId = userType === 'player' ? 1 : userType === 'venue_owner' ? 2 : 3;   // Player = 1, Venue Owner = 2, Admin = 3
        
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
            const roleName = userType === 'player' ? 'Player' : userType === 'venue_owner' ? 'Venue Owner' : 'Admin';
            
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

// POST /api/auth/login - Authenticate user and generate JWT token
// Handles user login with email/password verification and JWT token generation
router.post('/login', async (req, res) => {
    // Log login attempt for debugging and security monitoring
    console.log('🔐 Login attempt for:', req.body.email);
    
    let connection;
    try {
        // Establish database connection for authentication
        connection = await createConnection();
        console.log('✅ Database connection established');
        
        // Extract login credentials from request body
        const { email, password } = req.body;
        
        // Validate that both credentials are provided
        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password are required' });
        }
        
        // Retrieve user information with role details for authentication
        const [users] = await connection.execute(
            // Complex query joining Users and Roles tables to get complete user info
            'SELECT u.UserID, u.Name, u.Email, u.Password, u.PhoneNumber, u.RoleID, r.RoleName FROM Users u LEFT JOIN Roles r ON u.RoleID = r.RoleID WHERE u.Email = ?',
            [email] // Parameter binding to prevent SQL injection
        );
        
        // Check if user exists in database
        if (users.length === 0) {
            return res.status(401).json({ message: 'Invalid email or password' }); // Generic error for security
        }
        
        // Get the first (and only) user record
        const user = users[0];
        
        // Verify provided password against stored hash using bcrypt
        const isPasswordValid = await bcrypt.compare(password, user.Password);
        
        // Return error if password doesn't match
        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Invalid email or password' }); // Same generic error
        }
        
        // Generate JWT token for authenticated session
        const token = jwt.sign(
            { 
                userId: user.UserID,         // User's unique identifier
                email: user.Email,           // User's email address
                roleId: user.RoleID,         // User's role ID (1=Player, 2=Venue Owner)
                roleName: user.RoleName      // User's role name for easy access
            },
            JWT_SECRET,                      // Secret key for signing token
            { expiresIn: '24h' }            // Token expires in 24 hours for security
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
        const userType = user.RoleID === 1 ? 'player' : user.RoleID === 2 ? 'venue_owner' : user.RoleID === 3 ? 'admin' : 'unknown';
        
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
        const userType = user.RoleID === 1 ? 'player' : user.RoleID === 2 ? 'venue_owner' : user.RoleID === 3 ? 'admin' : 'unknown';
        
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

// Middleware function to authenticate JWT tokens on protected routes
// This function is used to verify user authentication before accessing protected endpoints
function authenticateToken(req, res, next) {
    // Extract Authorization header from request (format: "Bearer <token>")
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Extract token after "Bearer "
    
    // Check if token is provided
    if (!token) {
        return res.status(401).json({ message: 'Access token required' }); // Unauthorized
    }
    
    // Verify token signature and decode payload
    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            // Token is invalid, expired, or tampered with
            return res.status(403).json({ message: 'Invalid or expired token' }); // Forbidden
        }
        // Token is valid - add user info to request object for use in route handlers
        req.user = user;
        next(); // Continue to the next middleware or route handler
    });
}

module.exports = router;