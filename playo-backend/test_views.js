const mysql = require('mysql2/promise');

async function testViews() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '1234',
        database: 'dbms_cp'
    });

    try {
        console.log('🧪 Testing Views Creation...\n');
        
        // Test each view
        const views = [
            'user_profile_view',
            'venue_details_view', 
            'available_timeslots_view',
            'booking_summary_view',
            'popular_sports_view',
            'team_composition_view',
            'payment_summary_view'
        ];
        
        for (const view of views) {
            try {
                const [result] = await connection.execute(`SELECT COUNT(*) as count FROM ${view}`);
                console.log(`✅ ${view}: ${result[0].count} records`);
            } catch (err) {
                console.log(`❌ ${view}: ${err.message}`);
            }
        }
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await connection.end();
    }
}

testViews();