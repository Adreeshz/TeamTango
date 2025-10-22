// ================================================
// TeamTango User Permission Middleware
// Purpose: Middleware to check user permissions before database operations
// Date: October 5, 2025
// ================================================

const db = require('./db');

class PermissionManager {
    
    // Check if user has permission to perform action
    static async checkPermission(userID, tableName, action) {
        return new Promise((resolve, reject) => {
            const query = `
                SELECT up.*, r.RoleName 
                FROM UserPermissions up
                JOIN Roles r ON up.RoleID = r.RoleID
                JOIN Users u ON u.RoleID = r.RoleID
                WHERE u.UserID = ? AND up.TableName = ?
            `;
            
            db.query(query, [userID, tableName], (err, results) => {
                if (err) return reject(err);
                
                if (results.length === 0) {
                    return resolve({ hasPermission: false, role: 'Unknown' });
                }
                
                const permission = results[0];
                let hasPermission = false;
                
                switch (action.toLowerCase()) {
                    case 'select':
                    case 'read':
                        hasPermission = permission.CanSelect;
                        break;
                    case 'insert':
                    case 'create':
                        hasPermission = permission.CanInsert;
                        break;
                    case 'update':
                    case 'edit':
                        hasPermission = permission.CanUpdate;
                        break;
                    case 'delete':
                    case 'remove':
                        hasPermission = permission.CanDelete;
                        break;
                    default:
                        hasPermission = false;
                }
                
                resolve({
                    hasPermission,
                    role: permission.RoleName,
                    permissions: {
                        canSelect: permission.CanSelect,
                        canInsert: permission.CanInsert,
                        canUpdate: permission.CanUpdate,
                        canDelete: permission.CanDelete
                    }
                });
            });
        });
    }
    
    // Get user classification
    static async getUserClassification(userID) {
        return new Promise((resolve, reject) => {
            const query = `
                SELECT 
                    u.UserID,
                    u.Name,
                    u.Email,
                    r.RoleName,
                    r.RoleID,
                    CASE 
                        WHEN r.RoleID IN (1, 2) THEN 'Regular User'
                        WHEN r.RoleID = 3 THEN 'Admin User'
                        ELSE 'Unknown'
                    END as UserType,
                    CASE 
                        WHEN r.RoleID = 1 THEN 'Player - Can create teams, make bookings, join matches'
                        WHEN r.RoleID = 2 THEN 'Venue Owner - Can manage venues, timeslots, view bookings'
                        WHEN r.RoleID = 3 THEN 'Website Admin - Can moderate content, manage users'
                        ELSE 'Limited access'
                    END as AccessDescription
                FROM Users u
                LEFT JOIN Roles r ON u.RoleID = r.RoleID
                WHERE u.UserID = ?
            `;
            
            db.query(query, [userID], (err, results) => {
                if (err) return reject(err);
                if (results.length === 0) return resolve(null);
                resolve(results[0]);
            });
        });
    }
    
    // Log user activity
    static async logActivity(userID, action, tableName, recordID, details = '', req = null) {
        return new Promise((resolve, reject) => {
            const ipAddress = req ? (req.ip || req.connection.remoteAddress || 'Unknown') : 'System';
            const userAgent = req ? (req.get('User-Agent') || 'Unknown') : 'System';
            
            const query = `
                INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails, IPAddress, UserAgent)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `;
            
            db.query(query, [userID, action, tableName, recordID, details, ipAddress, userAgent], (err, result) => {
                if (err) return reject(err);
                resolve(result);
            });
        });
    }
}

// Middleware function to check permissions
const checkPermission = (tableName, action) => {
    return async (req, res, next) => {
        try {
            // Get userID from request (you'll need to implement authentication first)
            const userID = req.user?.id || req.headers['user-id'] || req.query.userId;
            
            if (!userID) {
                return res.status(401).json({ 
                    error: 'Authentication required',
                    message: 'User ID must be provided in headers or query parameters'
                });
            }
            
            // Check permission
            const permissionResult = await PermissionManager.checkPermission(userID, tableName, action);
            
            if (!permissionResult.hasPermission) {
                // Log unauthorized attempt
                await PermissionManager.logActivity(
                    userID, 
                    'UNAUTHORIZED_ATTEMPT', 
                    tableName, 
                    null, 
                    `Attempted ${action} on ${tableName} without permission`,
                    req
                );
                
                return res.status(403).json({
                    error: 'Access denied',
                    message: `You don't have permission to ${action} on ${tableName}`,
                    userRole: permissionResult.role
                });
            }
            
            // Add user info to request for use in route handlers
            req.userPermissions = permissionResult;
            req.userID = userID;
            
            next();
        } catch (error) {
            console.error('Permission check error:', error);
            res.status(500).json({ error: 'Permission check failed' });
        }
    };
};

// Middleware to check if user is admin
const requireAdmin = async (req, res, next) => {
    try {
        const userID = req.user?.id || req.headers['user-id'] || req.query.userId;
        
        if (!userID) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        
        const userClassification = await PermissionManager.getUserClassification(userID);
        
        if (!userClassification || userClassification.UserType !== 'Admin User') {
            return res.status(403).json({
                error: 'Admin access required',
                message: 'This operation requires administrator privileges'
            });
        }
        
        req.userClassification = userClassification;
        req.userID = userID;
        next();
    } catch (error) {
        console.error('Admin check error:', error);
        res.status(500).json({ error: 'Admin verification failed' });
    }
};

// Middleware to log all activities
const logActivity = (action, tableName) => {
    return async (req, res, next) => {
        const originalSend = res.send;
        
        res.send = async function(data) {
            // Log the activity if the request was successful
            if (res.statusCode >= 200 && res.statusCode < 300) {
                const userID = req.userID || req.headers['user-id'] || req.query.userId;
                const recordID = req.params.id || 'N/A';
                const details = `${action} operation on ${tableName}`;
                
                try {
                    if (userID) {
                        await PermissionManager.logActivity(userID, action, tableName, recordID, details, req);
                    }
                } catch (error) {
                    console.error('Activity logging error:', error);
                }
            }
            
            originalSend.call(this, data);
        };
        
        next();
    };
};

// Helper function to get user's allowed tables
const getAllowedTables = async (userID) => {
    return new Promise((resolve, reject) => {
        const query = `
            SELECT DISTINCT up.TableName, up.CanSelect, up.CanInsert, up.CanUpdate, up.CanDelete
            FROM UserPermissions up
            JOIN Users u ON u.RoleID = up.RoleID
            WHERE u.UserID = ?
        `;
        
        db.query(query, [userID], (err, results) => {
            if (err) return reject(err);
            resolve(results);
        });
    });
};

// Route to get user's permissions
const getUserPermissions = async (req, res) => {
    try {
        const userID = req.params.id || req.query.userId;
        
        if (!userID) {
            return res.status(400).json({ error: 'User ID is required' });
        }
        
        const classification = await PermissionManager.getUserClassification(userID);
        const allowedTables = await getAllowedTables(userID);
        
        res.json({
            user: classification,
            permissions: allowedTables,
            message: 'User permissions retrieved successfully'
        });
    } catch (error) {
        console.error('Get permissions error:', error);
        res.status(500).json({ error: 'Failed to get user permissions' });
    }
};

module.exports = {
    PermissionManager,
    checkPermission,
    requireAdmin,
    logActivity,
    getUserPermissions,
    getAllowedTables
};