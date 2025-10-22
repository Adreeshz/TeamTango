// Import required modules for sports management functionality
const express = require('express');        // Web framework for creating routes
const router = express.Router();          // Create router instance for sports endpoints
const db = require('../utils/db');        // Database connection pool

// GET /api/sports - Fetch all available sports
// Returns list of all sports in the system for dropdown menus and filtering
router.get('/', (req, res) => {
    // Simple query to get all sports sorted alphabetically for better UX
    db.query('SELECT * FROM Sports ORDER BY SportName', (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results); // Return all sports as JSON array
    });
});

// GET /api/sports/:id - Fetch single sport by ID
// Returns information for a specific sport
router.get('/:id', (req, res) => {
    // Query to get specific sport by ID with parameter binding for security
    db.query('SELECT * FROM Sports WHERE SportID=?', [req.params.id], (err, results) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json(results[0]); // Return first (only) result as single sport object
    });
});

// POST /api/sports/create - Add new sport to the platform
// Allows admins to add new sports categories (Cricket, Football, Basketball, etc.)
router.post('/create', (req, res) => {
    // Extract sport name from request body
    const { SportName } = req.body;
    // Insert new sport with parameter binding for security
    db.query('INSERT INTO sports (SportName) VALUES (?)', [SportName], (err, result) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        // Return success message with new sport ID
        res.json({ message: 'Sport created', SportID: result.insertId });
    });
});

// PUT /api/sports/update/:id - Update existing sport name
// Allows admins to modify sport names or correct typos
router.put('/update/:id', (req, res) => {
    // Extract updated sport name from request body
    const { SportName } = req.body;
    // Update sport record with WHERE clause for specific sport
    db.query('UPDATE Sports SET SportName=? WHERE SportID=?', [SportName, req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json({ message: 'Sport updated' }); // Return success message
    });
});

// DELETE /api/sports/delete/:id - Remove sport from platform
// Allows admins to delete sports (should check for existing venues/teams first)
router.delete('/delete/:id', (req, res) => {
    // Delete sport record by ID with parameter binding for security
    db.query('DELETE FROM Sports WHERE SportID=?', [req.params.id], (err, result) => {
        if(err) return res.status(500).json({ error: err }); // Handle database errors
        res.json({ message: 'Sport deleted' }); // Return success message
    });
});

// Export router for use in main server application
module.exports = router;
