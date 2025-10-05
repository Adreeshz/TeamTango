const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');

async function updateCorrectPasswords() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '1234',
        database: 'dbms_cp'
    });

    try {
        // Hash the demo passwords
        const playerHash = await bcrypt.hash('player123', 10);
        const venueHash = await bcrypt.hash('venue123', 10);

        console.log('Updating passwords for demo users...');

        // Update the demo users' passwords
        const [result1] = await connection.execute(
            'UPDATE Users SET Password = ? WHERE Email = ?',
            [playerHash, 'rahul.player@gmail.com']
        );
        console.log(`Updated player password: ${result1.affectedRows} rows affected`);

        const [result2] = await connection.execute(
            'UPDATE Users SET Password = ? WHERE Email = ?',
            [venueHash, 'priya.venue@gmail.com']
        );
        console.log(`Updated venue owner password: ${result2.affectedRows} rows affected`);

        console.log('✅ All passwords updated successfully!');

        // Verify the users exist with updated passwords
        const [users] = await connection.execute(
            'SELECT UserID, Name, Email, RoleID FROM Users WHERE Email IN (?, ?)',
            ['rahul.player@gmail.com', 'priya.venue@gmail.com']
        );

        console.log('\n📋 Demo credentials ready:');
        users.forEach(user => {
            const role = user.RoleID === 1 ? 'Player' : 'Venue Owner';
            const password = user.RoleID === 1 ? 'player123' : 'venue123';
            console.log(`${role}: ${user.Email} / ${password}`);
        });

    } catch (error) {
        console.error('❌ Error updating passwords:', error);
    } finally {
        await connection.end();
    }
}

updateCorrectPasswords();