const express = require('express');
const router = express.Router();
const db = require('../utils/db');

// GET all users
router.get('/', (req, res) => {
    db.query('SELECT * FROM Users', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET user by ID
router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Users WHERE UserID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

// POST create user
router.post('/create', (req, res) => {
    const { Name, Email, Gender, Password, PhoneNumber, Address, RoleID } = req.body;
    db.query(
        'INSERT INTO Users (Name, Email, Gender, Password, PhoneNumber, Address, RoleID) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [Name, Email, Gender, Password, PhoneNumber, Address, RoleID],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message: 'User created', UserID: result.insertId });
        }
    );
});

// PUT update user
router.put('/update/:id', (req, res) => {
    const { Name, Email, Gender, Password, PhoneNumber, Address, RoleID } = req.body;
    db.query(
        'UPDATE Users SET Name=?, Email=?, Gender=?, Password=?, PhoneNumber=?, Address=?, RoleID=? WHERE UserID=?',
        [Name, Email, Gender, Password, PhoneNumber, Address, RoleID, req.params.id],
        (err, result) => {
            if(err) return res.status(500).json({ error: err });
            res.json({ message:'User updated' });
        }
    );
});

// DELETE user
router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Users WHERE UserID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message:'User deleted' });
    });
});

module.exports = router;
