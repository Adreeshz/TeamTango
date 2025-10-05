const mysql = require('mysql2');

const db = mysql.createPool({
    host: 'localhost',
    user: 'root',           // Your MySQL user
    password: '1234',       // Your MySQL password
    database: 'dbms_cp'
});

db.getConnection((err, connection) => {
    if(err) console.error('❌ DB Connection Failed:', err);
    else {
        console.log('✅ Connected to MySQL dbms_cp');
        connection.release();
    }
});

module.exports = db;
