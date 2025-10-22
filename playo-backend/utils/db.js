// Import MySQL driver for Node.js database connectivity
const mysql = require('mysql2');

// Create a connection pool for efficient database connection management
// Connection pooling allows multiple simultaneous connections and automatic connection reuse
const db = mysql.createPool({
    host: 'localhost',          // MySQL server hostname (local development server)
    user: 'root',              // Database username (root user for development)
    password: '1234',          // Database password (should use environment variables in production)
    database: 'dbms_cp'        // Target database name for TeamTango sports booking system
});

// Test the database connection when the module is first loaded
// This helps identify connection issues early during application startup
db.getConnection((err, connection) => {
    if(err) {
        // Log connection failure with emoji for better visibility in console
        console.error('❌ DB Connection Failed:', err);
    } else {
        // Log successful connection with emoji for better UX
        console.log('✅ Connected to MySQL dbms_cp');
        connection.release(); // Return connection to pool for reuse
    }
});

// Export the database pool for use in route handlers
// This allows all route files to import and use the same connection pool
module.exports = db;
