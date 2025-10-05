const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    db.query('SELECT * FROM Notifications', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Notifications WHERE NotificationID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { UserID, Message, Date, Status } = req.body;
    db.query('INSERT INTO Notifications (UserID, Message, Date, Status) VALUES (?, ?, ?, ?)',
        [UserID, Message, Date, Status],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Notification added', NotificationID: result.insertId });
        }
    );
});

router.put('/update/:id', (req, res) => {
    const { UserID, Message, Date, Status } = req.body;
    db.query('UPDATE Notifications SET UserID=?, Message=?, Date=?, Status=? WHERE NotificationID=?',
        [UserID, Message, Date, Status, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Notification updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Notifications WHERE NotificationID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Notification deleted' });
    });
});

module.exports = router;
