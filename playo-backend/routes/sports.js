const express = require('express');
const router = express.Router();
const db = require('../utils/db');

router.get('/', (req, res) => {
    db.query('SELECT * FROM sports ORDER BY SportName', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Sports WHERE SportID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

router.post('/create', (req, res) => {
    const { SportName } = req.body;
    db.query('INSERT INTO sports (SportName) VALUES (?)', [SportName], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Sport created', SportID: result.insertId });
    });
});

router.put('/update/:id', (req, res) => {
    const { SportName } = req.body;
    db.query('UPDATE Sports SET SportName=? WHERE SportID=?', [SportName, req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Sport updated' });
    });
});

router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Sports WHERE SportID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Sport deleted' });
    });
});

module.exports = router;
