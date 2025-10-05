const mysql = require('mysql2/promise');

async function checkVenues() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '1234',
        database: 'dbms_cp'
    });

    try {
        console.log('=== VENUES TABLE DETAILED STRUCTURE ===');
        const [venuesCols] = await connection.execute('DESCRIBE venues');
        venuesCols.forEach(col => console.log(`${col.Field} - ${col.Type} - ${col.Null} - ${col.Default}`));
        
        console.log('\n=== ACTUAL VENUES DATA ===');
        const [venues] = await connection.execute('SELECT * FROM venues LIMIT 3');
        console.log(venues);
        
        console.log('\n=== TESTING VENUES API QUERY ===');
        try {
            const [result] = await connection.execute('SELECT VenueID, VenueName, Address FROM venues LIMIT 1');
            console.log('✅ Basic venue query works:', result);
        } catch (err) {
            console.log('❌ Basic venue query failed:', err.message);
        }
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await connection.end();
    }
}

checkVenues();