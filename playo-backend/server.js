const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 5000;

app.use(cors());
app.use(bodyParser.json());

// Serve static files from the frontend directory
app.use(express.static(path.join(__dirname, '../playo-frontend')));

// Import routes
console.log('Loading auth routes...');
const authRoutes = require('./routes/auth');
console.log('Auth routes loaded successfully');
const usersRoutes = require('./routes/users');
const analyticsRoutes = require('./routes/analytics');
const rolesRoutes = require('./routes/roles');
const sportsRoutes = require('./routes/sports');
const venuesRoutes = require('./routes/venues');
const timeslotsRoutes = require('./routes/timeslots');
const teamsRoutes = require('./routes/teams');
const teamMembersRoutes = require('./routes/teamMembers');
const bookingsRoutes = require('./routes/bookings');
const paymentsRoutes = require('./routes/payments');
const matchesRoutes = require('./routes/matches');
const feedbackRoutes = require('./routes/feedback');
const notificationsRoutes = require('./routes/notifications');

// Use routes
console.log('Registering auth routes at /api/auth');
app.use('/api/auth', authRoutes);
console.log('Registering user routes at /api/users');
app.use('/api/users', usersRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/roles', rolesRoutes);
app.use('/api/sports', sportsRoutes);
app.use('/api/venues', venuesRoutes);
app.use('/api/timeslots', timeslotsRoutes);
app.use('/api/teams', teamsRoutes);
app.use('/api/team-members', teamMembersRoutes);
app.use('/api/bookings', bookingsRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/matches', matchesRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/notifications', notificationsRoutes);

// Serve the main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../playo-frontend/index.html'));
});

// API status route
app.get('/api/status', (req, res) => res.json({ message: 'TeamTango API Running!', status: 'OK' }));

// Handle 404 for unmatched routes (optional)
app.use((req, res) => {
    if (req.path.startsWith('/api/')) {
        res.status(404).json({ error: 'API endpoint not found' });
    } else {
        // For non-API routes, serve the main page (SPA behavior)
        res.sendFile(path.join(__dirname, '../playo-frontend/index.html'));
    }
});

app.listen(PORT, () => {
    console.log(`🚀 TeamTango Server running at http://localhost:${PORT}`);
    console.log(`📁 Serving frontend from: ${path.join(__dirname, '../playo-frontend')}`);
    console.log(`🔗 Access the website at: http://localhost:${PORT}`);
    console.log(`🏏 Pune Sports Management System Ready!`);
});
