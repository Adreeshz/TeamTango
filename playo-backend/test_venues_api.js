const mysql = require('mysql2/promise');

async function testVenuesAPI() {
    try {
        // Create database connection
        const connection = await mysql.createConnection({
            host: 'localhost',
            user: 'root',
            password: 'root',
            database: 'dbms_cp'
        });

        console.log('=== TESTING VENUES API LOGIC ===');

        const query = `
            SELECT v.VenueID, v.VenueName, v.Address as Location, 
                   CASE 
                       WHEN v.VenueName LIKE '%Basketball%' OR v.VenueName LIKE '%Court%' THEN 'Basketball'
                       WHEN v.VenueName LIKE '%Football%' OR v.VenueName LIKE '%Ground%' THEN 'Football'
                       WHEN v.VenueName LIKE '%Tennis%' THEN 'Tennis'
                       WHEN v.VenueName LIKE '%Badminton%' THEN 'Badminton'
                       WHEN v.VenueName LIKE '%Cricket%' THEN 'Cricket'
                       ELSE 'Multi-Sport'
                   END as SportType,
                   CASE 
                       WHEN v.VenueName LIKE '%Basketball%' OR v.VenueName LIKE '%Court%' THEN 120
                       WHEN v.VenueName LIKE '%Football%' OR v.VenueName LIKE '%Ground%' THEN 150
                       WHEN v.VenueName LIKE '%Tennis%' THEN 130
                       WHEN v.VenueName LIKE '%Badminton%' THEN 100
                       WHEN v.VenueName LIKE '%Cricket%' THEN 140
                       ELSE 110
                   END as PricePerHour,
                   CASE 
                       WHEN v.VenueName LIKE '%Shiv Chhatrapati%' THEN 'Modern indoor courts with professional lighting and air conditioning'
                       WHEN v.VenueName LIKE '%Cooperage%' THEN 'Full-size field with natural grass and floodlights'
                       WHEN v.VenueName LIKE '%Deccan%' THEN 'Premium courts with synthetic surface and coaching facilities'
                       WHEN v.VenueName LIKE '%Sanas%' THEN 'Air-conditioned courts with wooden flooring'
                       WHEN v.VenueName LIKE '%MCA%' THEN 'Professional ground with turf wicket and practice nets'
                       ELSE 'Well-maintained sports facility with modern amenities'
                   END as Description,
                   ROUND(4.2 + (RAND() * 0.7), 1) as Rating
            FROM venues v 
            ORDER BY v.VenueName
        `;

        const [results] = await connection.execute(query);
        console.log('Raw query results:', JSON.stringify(results, null, 2));

        // Apply the same image logic as the API
        const venuesWithImages = results.map((venue, index) => {
            let imagePath = 'images/';
            
            // Map venue names to specific local images
            if (venue.VenueName.includes('Shiv Chhatrapati')) {
                imagePath += 'coep.jpg';
            } else if (venue.VenueName.includes('Deccan')) {
                imagePath += 'deccan.jpg';
            } else if (venue.VenueName.includes('Sanas')) {
                imagePath += 'badminton.png';
            } else if (venue.SportType === 'Basketball') {
                imagePath += 'basketball.jpg';
            } else if (venue.SportType === 'Football') {
                imagePath += 'football.jpg';
            } else if (venue.SportType === 'Tennis') {
                imagePath += 'tennis.jpg';
            } else if (venue.SportType === 'Badminton') {
                imagePath += 'badminton.png';
            } else if (venue.SportType === 'Cricket') {
                imagePath += 'cricket.jpg';
            } else if (venue.SportType === 'Volleyball') {
                imagePath += 'volleyball.jpg';
            } else {
                // Default fallback
                imagePath += 'basketball.jpg';
            }
            
            return {
                ...venue,
                Image: imagePath
            };
        });

        console.log('\n=== FINAL API RESPONSE WITH IMAGES ===');
        console.log(JSON.stringify(venuesWithImages, null, 2));

        await connection.end();
    } catch (error) {
        console.error('Error:', error);
    }
}

testVenuesAPI();