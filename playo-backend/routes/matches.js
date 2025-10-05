const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    const query = `
        SELECT m.MatchID, 
               t1.TeamName as Team1, 
               CASE 
                   WHEN t2.TeamName IS NOT NULL THEN t2.TeamName 
                   ELSE 'External Team' 
               END as Team2,
               v.VenueName as Venue,
               DATE(ts.StartTime) as MatchDate,
               TIME(ts.StartTime) as MatchTime,
               CASE 
                   WHEN ts.StartTime > NOW() THEN 'Upcoming'
                   WHEN m.Result IS NOT NULL THEN 'Completed'
                   ELSE 'Ongoing'
               END as Status,
               CASE 
                   WHEN m.Result = m.Team1ID THEN 'Won'
                   WHEN m.Result IS NOT NULL THEN 'Lost'
                   ELSE NULL
               END as Result,
               'League match in Pune' as Description
        FROM matches m
        JOIN teams t1 ON m.Team1ID = t1.TeamID
        LEFT JOIN teams t2 ON m.Team2ID = t2.TeamID
        JOIN timeslots ts ON m.SlotID = ts.SlotID
        JOIN venues v ON ts.VenueID = v.VenueID
        ORDER BY ts.StartTime DESC
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
    const { Team1ID, Team2ID, SlotID, SportID, Result } = req.body;
    db.query('INSERT INTO Matches (Team1ID, Team2ID, SlotID, SportID, Result) VALUES (?, ?, ?, ?, ?)',
        [Team1ID, Team2ID, SlotID, SportID, Result],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Match created', MatchID: result.insertId });
        }
    );
});

router.put('/update/:id', (req, res) => {
    const { Team1ID, Team2ID, SlotID, SportID, Result } = req.body;
    db.query('UPDATE Matches SET Team1ID=?, Team2ID=?, SlotID=?, SportID=?, Result=? WHERE MatchID=?',
        [Team1ID, Team2ID, SlotID, SportID, Result, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Match updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Matches WHERE MatchID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Match deleted' });
    });
});

module.exports = router;
