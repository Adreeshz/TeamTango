const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    // Use match_details view for pre-joined match data with winner calculation
    const query = `
        SELECT MatchID, 
               MatchTitle,
               Team1Name as Team1, 
               CASE 
                   WHEN Team2Name = 'External Team' THEN 'External Team'
                   WHEN Team2Name IS NOT NULL THEN Team2Name 
                   ELSE 'External Team' 
               END as Team2,
               VenueName as Venue,
               MatchDate,
               MatchTime,
               MatchStatus as Status,
               CASE 
                   WHEN MatchStatus = 'Completed' AND Team1Score > Team2Score THEN 'Team1 Won'
                   WHEN MatchStatus = 'Completed' AND Team2Score > Team1Score THEN 'Team2 Won'
                   WHEN MatchStatus = 'Completed' AND Team1Score = Team2Score THEN 'Draw'
                   ELSE NULL
               END as Result,
               Team1Score,
               Team2Score,
               Winner,
               SportName,
               CONCAT(MatchTitle, ' in ', VenueName) as Description
        FROM match_details
        ORDER BY MatchDate DESC, MatchTime DESC
    `;
    db.query(query, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Matches WHERE MatchID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime } = req.body;
    
    console.log('Creating match with data:', {
        MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime
    });
    
    // Validate required fields
    if (!MatchTitle || !Team1ID || !Team2ID || !VenueID || !MatchDate || !MatchTime) {
        return res.status(400).json({ 
            error: 'Missing required fields',
            message: 'All fields (MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime) are required'
        });
    }
    
    db.query('INSERT INTO Matches (MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, Team1Score, Team2Score, MatchStatus) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, 0, 0, 'Scheduled'],
        (err, result) => {
            if(err) {
                console.error('Database error creating match:', err);
                return res.status(500).json({ 
                    error: err.message || err,
                    message: 'Failed to create match'
                });
            }
            console.log('Match created successfully with ID:', result.insertId);
            res.json({ message: 'Match created', MatchID: result.insertId });
        }
    );
});

router.put('/update/:id', (req, res) => {
    const matchId = req.params.id;
    console.log('Match update requested for ID:', matchId, 'payload:', req.body);

    // For now, handle the most common case: status update
    if (req.body.MatchStatus) {
        const newStatus = req.body.MatchStatus;
        console.log(`Updating match ${matchId} status to: ${newStatus}`);
        
        db.query('UPDATE Matches SET MatchStatus = ? WHERE MatchID = ?', [newStatus, matchId], (err, result) => {
            if (err) {
                console.error('Database error updating match status:', err);
                return res.status(500).json({ error: err.message || err, message: 'Failed to update match status' });
            }

            if (result.affectedRows === 0) {
                console.log('No match found with ID:', matchId);
                return res.status(404).json({ message: 'Match not found' });
            }

            console.log('Match status updated successfully:', matchId, 'to', newStatus);
            return res.json({ message: 'Match updated successfully' });
        });
    } else {
        // For full match updates
        const { MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, Team1Score, Team2Score, MatchStatus } = req.body;
        
        db.query(
            'UPDATE Matches SET MatchTitle=?, Team1ID=?, Team2ID=?, VenueID=?, MatchDate=?, MatchTime=?, Team1Score=?, Team2Score=?, MatchStatus=? WHERE MatchID=?',
            [MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, Team1Score || 0, Team2Score || 0, MatchStatus || 'Scheduled', matchId],
            (err, result) => {
                if (err) {
                    console.error('Database error updating full match:', err);
                    return res.status(500).json({ error: err.message || err, message: 'Failed to update match' });
                }
                
                if (result.affectedRows === 0) {
                    return res.status(404).json({ message: 'Match not found' });
                }
                
                console.log('Match updated successfully:', matchId);
                return res.json({ message: 'Match updated successfully' });
            }
        );
    }
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Matches WHERE MatchID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Match deleted' });
    });
});

module.exports = router;
