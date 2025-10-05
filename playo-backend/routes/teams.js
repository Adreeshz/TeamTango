const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    const query = `
        SELECT t.TeamID, t.TeamName, s.SportName as Sport, 
               u.Name as CaptainName,
               (SELECT COUNT(*) FROM teammembers tm WHERE tm.TeamID = t.TeamID) as MemberCount,
               'Pune-based sports team' as Description,
               CURDATE() as CreatedDate
        FROM teams t 
        LEFT JOIN sports s ON t.SportID = s.SportID 
        LEFT JOIN users u ON t.CaptainID = u.UserID
        ORDER BY t.TeamName
    `;
    db.query(query, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM teams WHERE TeamID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { TeamName, SportID, UserID } = req.body;
    // Use UserID as CaptainID since user creating the team becomes captain
    db.query('INSERT INTO teams (TeamName, SportID, CaptainID) VALUES (?, ?, ?)',
        [TeamName, SportID, UserID || 1],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            
            // Add the captain as a team member
            const teamId = result.insertId;
            db.query('INSERT INTO teammembers (TeamID, UserID, Position) VALUES (?, ?, ?)',
                [teamId, UserID || 1, 'Captain'],
                (err2) => {
                    if(err2) console.log('Warning: Could not add captain as team member:', err2);
                    res.json({ message: 'Team created', TeamID: teamId });
                }
            );
        }
    );
});

router.put('/update/:id', (req, res) => {
    const { TeamName, SportID, CaptainID } = req.body;
    db.query('UPDATE Teams SET TeamName=?, SportID=?, CaptainID=? WHERE TeamID=?',
        [TeamName, SportID, CaptainID, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Team updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Teams WHERE TeamID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Team deleted' });
    });
});

module.exports = router;
