const mysql = require('mysql2/promise');

async function checkUsers() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '1234',
        database: 'dbms_cp'
    });

    try {
        // Check all users
        const [allUsers] = await connection.execute(
            'SELECT UserID, Name, Email, RoleID FROM Users ORDER BY RoleID, Email'
        );

        console.log('All users in database:');
        allUsers.forEach(user => {
            const role = user.RoleID === 1 ? 'Player' : user.RoleID === 2 ? 'Venue Owner' : 'Unknown';
            console.log(`- ${user.Name} (${user.Email}) - Role: ${role}`);
        });

    } catch (error) {
        console.error('Error checking users:', error);
    } finally {
        await connection.end();
    }
}

checkUsers();