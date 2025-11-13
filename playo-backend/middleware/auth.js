// Authentication and Authorization Middleware for Role-Based Access Control
// This module provides middleware functions to authenticate users and check permissions

const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');

// JWT secret key (should match the one in auth.js)
const JWT_SECRET = process.env.JWT_SECRET || 'teamtango_pune_secret_key_2025';

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

// Role Constants for easy reference
const ROLES = {
    PLAYER: 1,
    VENUE_OWNER: 2,
    ADMIN: 3
};

// Permission levels
const PERMISSIONS = {
    READ: 'read',
    CREATE: 'create',
    UPDATE: 'update',
    DELETE: 'delete',
    MANAGE: 'manage'
};

/**
 * Basic JWT Authentication Middleware
 * Verifies JWT token and adds user info to request object
 */
function authenticateToken(req, res, next) {
    console.log('=== AUTH MIDDLEWARE DEBUG ===');
    console.log('Request URL:', req.url);
    console.log('Request Method:', req.method);
    console.log('All headers:', JSON.stringify(req.headers, null, 2));
    
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    console.log('Auth middleware - Headers:', req.headers['authorization']);
    console.log('Auth middleware - Token extracted:', token ? 'Present' : 'Missing');
    
    if (!token) {
        console.log('Auth middleware - No token provided');
        return res.status(401).json({ 
            message: 'Access token required',
            error: 'MISSING_TOKEN'
        });
    }
    
    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            console.log('Auth middleware - Token verification failed:', err.message);
            return res.status(403).json({ 
                message: 'Invalid or expired token',
                error: 'INVALID_TOKEN'
            });
        }
        console.log('Auth middleware - Token verified for user:', user.userId, 'role:', user.roleId);
        req.user = user;
        next();
    });
}

/**
 * Role-based Authorization Middleware
 * Checks if user has required role(s)
 * @param {Array|Number} allowedRoles - Array of role IDs or single role ID
 */
function requireRole(allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ 
                message: 'Authentication required',
                error: 'NOT_AUTHENTICATED'
            });
        }
        
        const userRole = req.user.roleId;
        const rolesArray = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
        
        if (!rolesArray.includes(userRole)) {
            return res.status(403).json({ 
                message: 'Insufficient permissions',
                error: 'INSUFFICIENT_ROLE',
                required: rolesArray,
                current: userRole
            });
        }
        
        next();
    };
}

/**
 * Player Role Middleware - Only allows players
 */
function requirePlayer(req, res, next) {
    return requireRole(ROLES.PLAYER)(req, res, next);
}

/**
 * Venue Owner Role Middleware - Only allows venue owners
 */
function requireVenueOwner(req, res, next) {
    return requireRole(ROLES.VENUE_OWNER)(req, res, next);
}

/**
 * Admin Role Middleware - Only allows admins
 */
function requireAdmin(req, res, next) {
    return requireRole(ROLES.ADMIN)(req, res, next);
}

/**
 * Player or Admin Middleware - Allows players and admins
 */
function requirePlayerOrAdmin(req, res, next) {
    return requireRole([ROLES.PLAYER, ROLES.ADMIN])(req, res, next);
}

/**
 * Venue Owner or Admin Middleware - Allows venue owners and admins
 */
function requireVenueOwnerOrAdmin(req, res, next) {
    return requireRole([ROLES.VENUE_OWNER, ROLES.ADMIN])(req, res, next);
}

/**
 * Any Authenticated User Middleware - Allows any logged-in user
 */
function requireAnyRole(req, res, next) {
    return requireRole([ROLES.PLAYER, ROLES.VENUE_OWNER, ROLES.ADMIN])(req, res, next);
}

/**
 * Resource Ownership Middleware
 * Checks if user owns the resource or is an admin
 * @param {String} resourceIdParam - The parameter name containing resource ID
 * @param {String} tableName - The table to check ownership
 * @param {String} ownerField - The field that contains the owner ID
 */
function requireOwnershipOrAdmin(resourceIdParam, tableName, ownerField = 'UserID') {
    return async (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ 
                message: 'Authentication required',
                error: 'NOT_AUTHENTICATED'
            });
        }
        
        // Admins can access everything
        if (req.user.roleId === ROLES.ADMIN) {
            return next();
        }
        
        const resourceId = req.params[resourceIdParam];
        const userId = req.user.userId;
        
        if (!resourceId) {
            return res.status(400).json({ 
                message: 'Resource ID required',
                error: 'MISSING_RESOURCE_ID'
            });
        }
        
        let connection;
        try {
            connection = await createConnection();
            
            // Remove trailing 's' from table name if present for ID column
            const idColumn = tableName.endsWith('s') ? tableName.slice(0, -1) + 'ID' : tableName + 'ID';
            
            const [results] = await connection.execute(
                `SELECT ${ownerField} FROM ${tableName} WHERE ${idColumn} = ?`,
                [resourceId]
            );
            
            if (results.length === 0) {
                return res.status(404).json({ 
                    message: 'Resource not found',
                    error: 'RESOURCE_NOT_FOUND'
                });
            }
            
            const ownerId = results[0][ownerField];
            
            if (ownerId !== userId) {
                return res.status(403).json({ 
                    message: 'Access denied. You can only access your own resources.',
                    error: 'NOT_OWNER'
                });
            }
            
            next();
            
        } catch (error) {
            console.error('Ownership check error:', error);
            res.status(500).json({ 
                message: 'Failed to verify ownership',
                error: 'OWNERSHIP_CHECK_FAILED'
            });
        } finally {
            if (connection) {
                await connection.end();
            }
        }
    };
}

/**
 * Venue Ownership Middleware
 * Checks if user owns the venue or is an admin
 */
function requireVenueOwnership(req, res, next) {
    return requireOwnershipOrAdmin('venueId', 'Venues', 'OwnerID')(req, res, next);
}

/**
 * Team Ownership Middleware
 * Checks if user is team captain or admin
 */
function requireTeamOwnership(req, res, next) {
    return requireOwnershipOrAdmin('id', 'Teams', 'CaptainID')(req, res, next);
}

/**
 * User Profile Ownership Middleware
 * Checks if user is accessing their own profile or is admin
 */
function requireProfileOwnership(req, res, next) {
    if (!req.user) {
        return res.status(401).json({ 
            message: 'Authentication required',
            error: 'NOT_AUTHENTICATED'
        });
    }
    
    // Admins can access any profile
    if (req.user.roleId === ROLES.ADMIN) {
        return next();
    }
    
    const requestedUserId = parseInt(req.params.id || req.params.userId);
    const currentUserId = req.user.userId;
    
    if (requestedUserId !== currentUserId) {
        return res.status(403).json({ 
            message: 'Access denied. You can only access your own profile.',
            error: 'NOT_OWNER'
        });
    }
    
    next();
}

/**
 * Permission-based Middleware
 * Checks if user has specific permission for a table/action
 * @param {String} tableName - The table name
 * @param {String} action - The action (CREATE, READ, UPDATE, DELETE)
 */
function requirePermission(tableName, action) {
    return async (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ 
                message: 'Authentication required',
                error: 'NOT_AUTHENTICATED'
            });
        }
        
        let connection;
        try {
            connection = await createConnection();
            
            // Try using stored procedure first
            try {
                const [result] = await connection.execute(
                    'CALL CheckUserPermission(?, ?, ?)',
                    [req.user.userId, tableName, action.toUpperCase()]
                );
                
                const hasPermission = result[0][0].HasPermission === 1;
                
                if (!hasPermission) {
                    return res.status(403).json({ 
                        message: `Insufficient permissions for ${action} on ${tableName}`,
                        error: 'INSUFFICIENT_PERMISSION'
                    });
                }
                
                next();
                
            } catch (procError) {
                // Fallback to manual permission check
                const actionField = `Can${action.charAt(0).toUpperCase() + action.slice(1).toLowerCase()}`;
                
                const [permissions] = await connection.execute(
                    `SELECT up.${actionField} as HasPermission 
                     FROM Users u 
                     LEFT JOIN UserPermissions up ON u.RoleID = up.RoleID AND up.TableName = ?
                     WHERE u.UserID = ?`,
                    [tableName, req.user.userId]
                );
                
                const hasPermission = permissions.length > 0 ? permissions[0].HasPermission === 1 : false;
                
                if (!hasPermission) {
                    return res.status(403).json({ 
                        message: `Insufficient permissions for ${action} on ${tableName}`,
                        error: 'INSUFFICIENT_PERMISSION'
                    });
                }
                
                next();
            }
            
        } catch (error) {
            console.error('Permission check error:', error);
            res.status(500).json({ 
                message: 'Failed to check permissions',
                error: 'PERMISSION_CHECK_FAILED'
            });
        } finally {
            if (connection) {
                await connection.end();
            }
        }
    };
}

/**
 * Request Logger Middleware for Audit Trail
 */
function logRequest(req, res, next) {
    const timestamp = new Date().toISOString();
    const user = req.user ? `User:${req.user.userId}(${req.user.roleName})` : 'Anonymous';
    
    console.log(`[${timestamp}] ${req.method} ${req.path} - ${user} - IP:${req.ip}`);
    
    next();
}

module.exports = {
    // Basic authentication
    authenticateToken,
    
    // Role-based authorization
    requireRole,
    requirePlayer,
    requireVenueOwner,
    requireAdmin,
    requirePlayerOrAdmin,
    requireVenueOwnerOrAdmin,
    requireAnyRole,
    
    // Resource ownership
    requireOwnershipOrAdmin,
    requireVenueOwnership,
    requireTeamOwnership,
    requireProfileOwnership,
    
    // Permission-based authorization
    requirePermission,
    
    // Utility
    logRequest,
    
    // Constants
    ROLES,
    PERMISSIONS
};