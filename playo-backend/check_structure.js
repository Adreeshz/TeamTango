const mysql = require('mysql2/promise');

async function checkDatabaseStructure() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '1234',
        database: 'dbms_cp'
    });

    try {
        console.log('=== CHECKING DATABASE STRUCTURE ===\n');
        
        // Get all tables
        const [tables] = await connection.execute('SHOW TABLES');
        console.log('Tables found:', tables.map(t => Object.values(t)[0]));
        
        // Check Users table structure
        console.log('\n=== USERS TABLE STRUCTURE ===');
        const [usersCols] = await connection.execute('DESCRIBE Users');
        usersCols.forEach(col => console.log(`${col.Field} - ${col.Type}`));
        
        // Check if the problematic query works
        console.log('\n=== TESTING SIMPLE USER VIEW ===');
        try {
            const [result] = await connection.execute('SELECT UserID, Name, Email FROM Users LIMIT 1');
            console.log('✅ Basic user query works');
        } catch (err) {
            console.log('❌ Basic user query failed:', err.message);
        }
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await connection.end();
    }
}

checkDatabaseStructure();