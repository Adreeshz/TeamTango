const mysql = require('mysql2/promise');

async function checkCurrentPasswords() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '1234',
        database: 'dbms_cp'
    });

    try {
        const [users] = await connection.execute(
            'SELECT UserID, Name, Email, Password FROM Users WHERE Email IN (?, ?)',
            ['rahul.player@gmail.com', 'priya.venue@gmail.com']
        );

        console.log('Current demo user passwords in database:');
        users.forEach(user => {
            console.log(`${user.Email}: ${user.Password.substring(0, 20)}...`);
        });

    } catch (error) {
        console.error('Error checking passwords:', error);
    } finally {
        await connection.end();
    }
}

checkCurrentPasswords();