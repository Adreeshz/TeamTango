const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    db.query('SELECT * FROM Payments', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Payments WHERE PaymentID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { Method, Amount, Status, TransactionDate } = req.body;
    db.query('INSERT INTO Payments (Method, Amount, Status, TransactionDate) VALUES (?, ?, ?, ?)',
        [Method, Amount, Status, TransactionDate],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Payment recorded', PaymentID: result.insertId });
        }
    );
});

router.put('/update/:id', (req, res) => {
    const { Method, Amount, Status, TransactionDate } = req.body;
    db.query('UPDATE Payments SET Method=?, Amount=?, Status=?, TransactionDate=? WHERE PaymentID=?',
        [Method, Amount, Status, TransactionDate, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'Payment updated' });
        }
    );
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Payments WHERE PaymentID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Payment deleted' });
    });
});

module.exports = router;
