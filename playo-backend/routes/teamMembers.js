const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    db.query('SELECT * FROM TeamMembers', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:teamId/:userId', (req, res) => {
    db.query('SELECT * FROM TeamMembers WHERE TeamID=? AND UserID=?',
        [req.params.teamId, req.params.userId],
        (err, results) => {
            if(err) return res.status(500).json({ error: err });
            res.json(results[0]);
        }
    );
});

router.post('/create', (req, res) => {
    const { TeamID, UserID, Position } = req.body;
    db.query('INSERT INTO TeamMembers (TeamID, UserID, Position) VALUES (?, ?, ?)',
        [TeamID, UserID, Position],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'TeamMember added' });
        }
    );
});

router.put('/update/:teamId/:userId', (req, res) => {
    const { Position } = req.body;
    db.query('UPDATE TeamMembers SET Position=? WHERE TeamID=? AND UserID=?',
        [Position, req.params.teamId, req.params.userId],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'TeamMember updated' });
        }
    );
});

router.delete('/delete/:teamId/:userId', (req, res) => {
    db.query('DELETE FROM TeamMembers WHERE TeamID=? AND UserID=?',
        [req.params.teamId, req.params.userId],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'TeamMember deleted' });
        }
    );
});

module.exports = router;
