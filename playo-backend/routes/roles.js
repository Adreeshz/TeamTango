const express = require('express');
const router = express.Router();
const db = require('../utils/db');

// GET all roles
router.get('/', (req, res) => {
    db.query('SELECT * FROM Roles', (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// GET role by ID
router.get('/:id', (req, res) => {
    db.query('SELECT * FROM Roles WHERE RoleID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json(results[0]);
    });
});

// POST create role
router.post('/create', (req, res) => {
    const { RoleName } = req.body;
    db.query('INSERT INTO Roles (RoleName) VALUES (?)', [RoleName], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Role created', RoleID: result.insertId });
    });
});

// PUT update role
router.put('/update/:id', (req, res) => {
    const { RoleName } = req.body;
    db.query('UPDATE Roles SET RoleName=? WHERE RoleID=?', [RoleName, req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Role updated' });
    });
});

// DELETE role
router.delete('/delete/:id', (req, res) => {
    db.query('DELETE FROM Roles WHERE RoleID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err });
        res.json({ message: 'Role deleted' });
    });
});

module.exports = router;
