// Import required modules for team management functionality
const express = require('express');        // Web framework for creating routes
const router = express.Router();          // Create router instance for team endpoints
const mysql = require('mysql2/promise');   // MySQL database driver with promise support
const {
    authenticateToken,
    requireAdmin,
    requirePlayerOrAdmin,
    requireAnyRole,
    requireTeamOwnership,
    logRequest,
    ROLES
} = require('../middleware/auth');

// Database configuration
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '1234',
    database: 'dbms_cp'
};

// Helper function to create database connection
async function createConnection() {
    return await mysql.createConnection(dbConfig);
}

// Apply request logging to all routes
router.use(logRequest);

// GET /api/teams - Fetch all teams (Public access for viewing)
// Provides comprehensive team data including captain info and member counts
router.get('/', async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        // Complex query joining multiple tables for complete team information
        const [teams] = await connection.execute(`
            SELECT 
                t.TeamID, 
                t.TeamName, 
                s.SportName as Sport,
                t.SportID,
                u.Name as CaptainName,
                u.UserID as CaptainID,
                u.Email as CaptainEmail,
                (SELECT COUNT(*) FROM TeamMembers tm WHERE tm.TeamID = t.TeamID) as MemberCount,
                0 as TotalBookings
            FROM Teams t
            LEFT JOIN Sports s ON t.SportID = s.SportID
            LEFT JOIN Users u ON t.CaptainID = u.UserID
            ORDER BY t.TeamName
        `);
        
        res.json({
            message: 'Teams retrieved successfully',
            teams: teams,
            total: teams.length
        });
        
    } catch (error) {
        console.error('Get teams error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve teams',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/teams/my - Get teams where current user is captain or member (Player only)
router.get('/my', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const userId = req.user.userId;
        
        const [teams] = await connection.execute(`
            SELECT DISTINCT
                t.TeamID, 
                t.TeamName, 
                s.SportName as Sport,
                t.SportID,
                u.Name as CaptainName,
                t.CaptainID,
                tm.JoinedDate,
                (SELECT COUNT(*) FROM TeamMembers tm2 WHERE tm2.TeamID = t.TeamID) as MemberCount,
                CASE WHEN t.CaptainID = ? THEN 'Captain' ELSE 'Member' END as UserRole
            FROM Teams t
            LEFT JOIN Sports s ON t.SportID = s.SportID
            LEFT JOIN Users u ON t.CaptainID = u.UserID
            LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.UserID = ?
            WHERE t.CaptainID = ? OR tm.UserID = ?
            ORDER BY t.TeamName
        `, [userId, userId, userId, userId]);
        
        res.json({
            message: 'Your teams retrieved successfully',
            teams: teams,
            total: teams.length
        });
        
    } catch (error) {
        console.error('Get my teams error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve your teams',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// GET /api/teams/:id - Fetch single team by ID with member details
router.get('/:id', async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const teamId = parseInt(req.params.id);
        
        // Get team details
        const [teams] = await connection.execute(`
            SELECT 
                t.TeamID, 
                t.TeamName, 
                s.SportName as Sport,
                t.SportID,
                u.Name as CaptainName,
                u.UserID as CaptainID,
                u.Email as CaptainEmail,
                u.PhoneNumber as CaptainPhone
            FROM Teams t
            LEFT JOIN Sports s ON t.SportID = s.SportID
            LEFT JOIN Users u ON t.CaptainID = u.UserID
            WHERE t.TeamID = ?
        `, [teamId]);
        
        if (teams.length === 0) {
            return res.status(404).json({ message: 'Team not found' });
        }
        
        // Get team members
        const [members] = await connection.execute(`
            SELECT 
                tm.UserID,
                u.Name as MemberName,
                u.Email as MemberEmail,
                tm.JoinedDate
            FROM TeamMembers tm
            LEFT JOIN Users u ON tm.UserID = u.UserID
            WHERE tm.TeamID = ?
            ORDER BY tm.JoinedDate
        `, [teamId]);
        
        const team = teams[0];
        team.members = members;
        team.memberCount = members.length;
        
        res.json({
            message: 'Team retrieved successfully',
            team: team
        });
        
    } catch (error) {
        console.error('Get team error:', error);
        res.status(500).json({ 
            message: 'Failed to retrieve team',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// POST /api/teams/create - Create new team (Player or Admin only)
router.post('/create', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const { TeamName, SportID } = req.body;
        const CaptainID = req.user.userId;
        
        // Validate required fields
        if (!TeamName || !SportID) {
            return res.status(400).json({ message: 'Team name and sport are required' });
        }
        
        // Check if sport exists
        const [sports] = await connection.execute(
            'SELECT SportID FROM Sports WHERE SportID = ?',
            [SportID]
        );
        
        if (sports.length === 0) {
            return res.status(404).json({ message: 'Sport not found' });
        }
        
        // Check if team name already exists for this sport
        const [existingTeams] = await connection.execute(
            'SELECT TeamID FROM Teams WHERE TeamName = ? AND SportID = ?',
            [TeamName, SportID]
        );
        
        if (existingTeams.length > 0) {
            return res.status(409).json({ message: 'A team with this name already exists for this sport' });
        }
        
        // Create team using stored procedure (if available)
        try {
            const [result] = await connection.execute(
                'CALL CreateTeam(?, ?, ?)',
                [TeamName, SportID, CaptainID]
            );
            
            const newTeamId = result[0][0].TeamID;
            
            res.status(201).json({
                message: 'Team created successfully',
                team: {
                    id: newTeamId,
                    name: TeamName,
                    sportId: SportID,
                    captainId: CaptainID
                }
            });
            
        } catch (procError) {
            // Fallback to manual team creation
            console.log('Stored procedure not available, using manual creation:', procError.message);
            
            // Begin transaction
            await connection.beginTransaction();
            
            try {
                // Create team
                const [teamResult] = await connection.execute(
                    'INSERT INTO Teams (TeamName, SportID, CaptainID) VALUES (?, ?, ?)',
                    [TeamName, SportID, CaptainID]
                );
                
                const newTeamId = teamResult.insertId;
                
                // Add captain as team member
                await connection.execute(
                    'INSERT INTO TeamMembers (TeamID, UserID) VALUES (?, ?)',
                    [newTeamId, CaptainID]
                );
                
                // Commit transaction
                await connection.commit();
                
                // Log team creation
                try {
                    await connection.execute(
                        'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                        [CaptainID, 'CREATE', 'Teams', newTeamId, null, JSON.stringify({ TeamName, SportID, CaptainID })]
                    );
                } catch (logError) {
                    console.log('Audit logging failed:', logError.message);
                }
                
                res.status(201).json({
                    message: 'Team created successfully',
                    team: {
                        id: newTeamId,
                        name: TeamName,
                        sportId: SportID,
                        captainId: CaptainID
                    }
                });
                
            } catch (createError) {
                await connection.rollback();
                throw createError;
            }
        }
        
    } catch (error) {
        console.error('Create team error:', error);
        res.status(500).json({ 
            message: 'Failed to create team',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// POST /api/teams/:id/join - Join team (Player only)
router.post('/:id/join', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const teamId = parseInt(req.params.id);
        const userId = req.user.userId;
        
        // Check if team exists
        const [teams] = await connection.execute(
            'SELECT TeamID, TeamName, CaptainID FROM Teams WHERE TeamID = ?',
            [teamId]
        );
        
        if (teams.length === 0) {
            return res.status(404).json({ message: 'Team not found' });
        }
        
        const team = teams[0];
        
        // Check if user is already a member
        const [existingMember] = await connection.execute(
            'SELECT UserID FROM TeamMembers WHERE TeamID = ? AND UserID = ?',
            [teamId, userId]
        );
        
        if (existingMember.length > 0) {
            return res.status(409).json({ message: 'You are already a member of this team' });
        }
        
        // Check if user is the captain (captain is automatically a member)
        if (team.CaptainID === userId) {
            return res.status(409).json({ message: 'You are the captain of this team' });
        }
        
        // Add user to team
        await connection.execute(
            'INSERT INTO TeamMembers (TeamID, UserID) VALUES (?, ?)',
            [teamId, userId]
        );
        
        // Log team join
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [userId, 'CREATE', 'TeamMembers', teamId, null, JSON.stringify({ TeamID: teamId, UserID: userId })]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.status(200).json({
            message: 'Successfully joined team',
            team: {
                id: teamId,
                name: team.TeamName
            }
        });
        
    } catch (error) {
        console.error('Join team error:', error);
        res.status(500).json({ 
            message: 'Failed to join team',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// DELETE /api/teams/:id/leave - Leave team (Player only)
router.delete('/:id/leave', authenticateToken, requirePlayerOrAdmin, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const teamId = parseInt(req.params.id);
        const userId = req.user.userId;
        
        // Check if team exists and get captain info
        const [teams] = await connection.execute(
            'SELECT TeamID, TeamName, CaptainID FROM Teams WHERE TeamID = ?',
            [teamId]
        );
        
        if (teams.length === 0) {
            return res.status(404).json({ message: 'Team not found' });
        }
        
        const team = teams[0];
        
        // Captains cannot leave their own team (they must transfer captaincy or delete team)
        if (team.CaptainID === userId) {
            return res.status(400).json({ message: 'Captains cannot leave their team. Transfer captaincy or delete the team.' });
        }
        
        // Check if user is a member
        const [memberCheck] = await connection.execute(
            'SELECT UserID FROM TeamMembers WHERE TeamID = ? AND UserID = ?',
            [teamId, userId]
        );
        
        if (memberCheck.length === 0) {
            return res.status(404).json({ message: 'You are not a member of this team' });
        }
        
        // Remove user from team
        await connection.execute(
            'DELETE FROM TeamMembers WHERE TeamID = ? AND UserID = ?',
            [teamId, userId]
        );
        
        // Log team leave
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [userId, 'DELETE', 'TeamMembers', teamId, JSON.stringify({ TeamID: teamId, UserID: userId }), null]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({
            message: 'Successfully left team',
            team: {
                id: teamId,
                name: team.TeamName
            }
        });
        
    } catch (error) {
        console.error('Leave team error:', error);
        res.status(500).json({ 
            message: 'Failed to leave team',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// PUT /api/teams/update/:id - Update team information (Captain or Admin only)
router.put('/update/:id', authenticateToken, requireTeamOwnership, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const teamId = parseInt(req.params.id);
        const { TeamName, SportID } = req.body;
        
        // Get current team data for audit log
        const [currentTeam] = await connection.execute(
            'SELECT * FROM Teams WHERE TeamID = ?',
            [teamId]
        );
        
        if (currentTeam.length === 0) {
            return res.status(404).json({ message: 'Team not found' });
        }
        
        let updateFields = [];
        let updateValues = [];
        let updatedData = {};
        
        if (TeamName !== undefined) {
            // Check if new team name conflicts with existing teams for same sport
            const currentSportID = SportID || currentTeam[0].SportID;
            const [nameConflict] = await connection.execute(
                'SELECT TeamID FROM Teams WHERE TeamName = ? AND SportID = ? AND TeamID != ?',
                [TeamName, currentSportID, teamId]
            );
            
            if (nameConflict.length > 0) {
                return res.status(409).json({ message: 'A team with this name already exists for this sport' });
            }
            
            updateFields.push('TeamName = ?');
            updateValues.push(TeamName);
            updatedData.TeamName = TeamName;
        }
        
        if (SportID !== undefined) {
            // Verify sport exists
            const [sportCheck] = await connection.execute(
                'SELECT SportID FROM Sports WHERE SportID = ?',
                [SportID]
            );
            
            if (sportCheck.length === 0) {
                return res.status(404).json({ message: 'Sport not found' });
            }
            
            updateFields.push('SportID = ?');
            updateValues.push(SportID);
            updatedData.SportID = SportID;
        }
        
        if (updateFields.length === 0) {
            return res.status(400).json({ message: 'No valid fields to update' });
        }
        
        updateValues.push(teamId);
        await connection.execute(
            `UPDATE Teams SET ${updateFields.join(', ')} WHERE TeamID = ?`,
            updateValues
        );
        
        // Log the update
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'UPDATE', 'Teams', teamId, JSON.stringify(currentTeam[0]), JSON.stringify(updatedData)]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Team updated successfully',
            updatedFields: Object.keys(updatedData)
        });
        
    } catch (error) {
        console.error('Update team error:', error);
        res.status(500).json({ 
            message: 'Failed to update team',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// DELETE /api/teams/delete/:id - Delete team (Captain or Admin only)
router.delete('/delete/:id', authenticateToken, requireTeamOwnership, async (req, res) => {
    let connection;
    try {
        connection = await createConnection();
        
        const teamId = parseInt(req.params.id);
        
        // Get team data before deletion for audit log
        const [teamToDelete] = await connection.execute(
            'SELECT * FROM Teams WHERE TeamID = ?',
            [teamId]
        );
        
        if (teamToDelete.length === 0) {
            return res.status(404).json({ message: 'Team not found' });
        }
        
        // Check for active bookings
        const [activeBookings] = await connection.execute(
            'SELECT COUNT(*) as count FROM Bookings WHERE TeamID = ? AND Status IN ("Confirmed", "Pending")',
            [teamId]
        );
        
        if (activeBookings[0].count > 0) {
            return res.status(400).json({ 
                message: 'Cannot delete team with active bookings. Please cancel or complete all bookings first.',
                activeBookings: activeBookings[0].count
            });
        }
        
        // Delete team (this will cascade to related records based on foreign key constraints)
        await connection.execute('DELETE FROM Teams WHERE TeamID = ?', [teamId]);
        
        // Log the deletion
        try {
            await connection.execute(
                'INSERT INTO AuditLog (UserID, Action, TableName, RecordID, OldValues, NewValues) VALUES (?, ?, ?, ?, ?, ?)',
                [req.user.userId, 'DELETE', 'Teams', teamId, JSON.stringify(teamToDelete[0]), null]
            );
        } catch (logError) {
            console.log('Audit logging failed:', logError.message);
        }
        
        res.json({ 
            message: 'Team deleted successfully',
            deletedTeam: {
                id: teamToDelete[0].TeamID,
                name: teamToDelete[0].TeamName
            }
        });
        
    } catch (error) {
        console.error('Delete team error:', error);
        res.status(500).json({ 
            message: 'Failed to delete team',
            error: error.message 
        });
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

// Export router for use in main server application
module.exports = router;
