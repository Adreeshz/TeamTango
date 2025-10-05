const mysql = require('mysql2/promise');

async function checkAllTableStructures() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '1234',
        database: 'dbms_cp'
    });

    try {
        const tables = ['users', 'roles', 'venues', 'sports', 'timeslots', 'bookings', 'payments', 'teams', 'teammembers'];
        
        for (const table of tables) {
            console.log(`\n=== ${table.toUpperCase()} TABLE ===`);
            try {
                const [cols] = await connection.execute(`DESCRIBE ${table}`);
                cols.forEach(col => console.log(`${col.Field} - ${col.Type}`));
            } catch (err) {
                console.log(`❌ Table ${table} not found`);
            }
        }
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await connection.end();
    }
}

checkAllTableStructures();