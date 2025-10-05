const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
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
    db.query(query, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        
        // Add local images based on venue names
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
        
        res.json(venuesWithImages);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM venues WHERE VenueID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { VenueName, Address, OwnerID } = req.body;
    db.query('INSERT INTO venues (VenueName, Address, OwnerID) VALUES (?, ?, ?)',
        [VenueName, Address, OwnerID],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Venue created', VenueID: result.insertId });
        }
    );
});

router.put('/update/:id', (req, res) => {
    const { VenueName, Address, OwnerID } = req.body;
    db.query('UPDATE Venues SET VenueName=?, Address=?, OwnerID=? WHERE VenueID=?',
        [VenueName, Address, OwnerID, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Venue updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Venues WHERE VenueID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Venue deleted' });
    });
});

module.exports = router;
