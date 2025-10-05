const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    db.query('SELECT * FROM Feedback', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Feedback WHERE FeedbackID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { UserID, VenueID, Rating, Comment, Date } = req.body;
    db.query('INSERT INTO Feedback (UserID, VenueID, Rating, Comment, Date) VALUES (?, ?, ?, ?, ?)',
        [UserID, VenueID, Rating, Comment, Date],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Feedback added', FeedbackID: result.insertId });
        }
    );
});

router.put('/update/:id', (req, res) => {
    const { UserID, VenueID, Rating, Comment, Date } = req.body;
    db.query('UPDATE Feedback SET UserID=?, VenueID=?, Rating=?, Comment=?, Date=? WHERE FeedbackID=?',
        [UserID, VenueID, Rating, Comment, Date, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Feedback updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Feedback WHERE FeedbackID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Feedback deleted' });
    });
});

module.exports = router;
