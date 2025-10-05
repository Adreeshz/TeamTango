const express = require('express');
const router = express.Router();
const db = require('../utils/db');
const { checkPermission, logActivity, PermissionManager } = require('../utils/permissions');

// GET all teams (everyone can view teams)
router.get('/', checkPermission('Teams', 'SELECT'), logActivity('SELECT', 'Teams'), (req, res) => {
    db.query(`
        SELECT t.*, u.Name as CaptainName, s.SportName 
        FROM Teams t
        LEFT JOIN Users u ON t.CaptainID = u.UserID
        LEFT JOIN Sports s ON t.SportID = s.SportID
        ORDER BY t.CreatedAt DESC
    `, (err, results) => {
        if(err) return res.status(500).json({ error: err });
        res.json({
            teams: results,
            total: results.length,
            message: 'Teams retrieved successfully'
        });
    });
});

// GET team by ID (everyone can view)
router.get('/:id', checkPermission('Teams', 'SELECT'), (req, res) => {
    const teamID = req.params.id;
    
    db.query(`
        SELECT t.*, u.Name as CaptainName, s.SportName 
        FROM Teams t
        LEFT JOIN Users u ON t.CaptainID = u.UserID
        LEFT JOIN Sports s ON t.SportID = s.SportID
        WHERE t.TeamID = ?
    `, [teamID], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        if(results.length === 0) return res.status(404).json({ error: 'Team not found' });
        
        // Get team members
        db.query(`
            SELECT tm.*, u.Name as PlayerName, u.Email as PlayerEmail
            FROM TeamMembers tm
            JOIN Users u ON tm.UserID = u.UserID
            WHERE tm.TeamID = ?
        `, [teamID], (err, members) => {
            if(err) return res.status(500).json({ error: err });
            
            res.json({
                team: results[0],
                members: members,
                message: 'Team details retrieved successfully'
            });
        });
    });
});

// POST create team (only players can create teams)
router.post('/create', checkPermission('Teams', 'INSERT'), logActivity('INSERT', 'Teams'), async (req, res) => {
    try {
        const { TeamName, SportID, Description } = req.body;
        const currentUserID = req.userID;
        
        if (!TeamName || !SportID) {
            return res.status(400).json({ 
                error: 'Missing required fields', 
                required: ['TeamName', 'SportID']
            });
        }
        
        // Check if user is a player (RoleID = 1)
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        if (userClassification.RoleID !== 1) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only players can create teams'
            });
        }
        
        // Check if team name already exists for this sport
        db.query('SELECT TeamID FROM Teams WHERE TeamName = ? AND SportID = ?', 
            [TeamName, SportID], (err, existing) => {
            if (err) return res.status(500).json({ error: err });
            if (existing.length > 0) {
                return res.status(409).json({ 
                    error: 'Team name already exists for this sport' 
                });
            }
            
            // Create the team
            db.query(
                'INSERT INTO Teams (TeamName, CaptainID, SportID, Description) VALUES (?, ?, ?, ?)',
                [TeamName, currentUserID, SportID, Description],
                (err, result) => {
                    if(err) return res.status(500).json({ error: err });
                    
                    const teamID = result.insertId;
                    
                    // Automatically add creator as team member
                    db.query(
                        'INSERT INTO TeamMembers (TeamID, UserID, JoinDate) VALUES (?, ?, NOW())',
                        [teamID, currentUserID],
                        (err) => {
                            if (err) console.error('Error adding creator to team members:', err);
                        }
                    );
                    
                    res.status(201).json({ 
                        message: 'Team created successfully', 
                        TeamID: teamID,
                        TeamName: TeamName,
                        CaptainID: currentUserID,
                        note: 'You have been automatically added as a team member'
                    });
                }
            );
        });
    } catch (error) {
        console.error('Create team error:', error);
        res.status(500).json({ error: 'Failed to create team' });
    }
});

// PUT update team (only team captain or admins can update)
router.put('/update/:id', checkPermission('Teams', 'UPDATE'), logActivity('UPDATE', 'Teams'), async (req, res) => {
    try {
        const teamID = req.params.id;
        const currentUserID = req.userID;
        const { TeamName, Description, SportID } = req.body;
        
        // Check if user is team captain or admin
        const teamResult = await new Promise((resolve, reject) => {
            db.query('SELECT CaptainID FROM Teams WHERE TeamID = ?', [teamID], (err, results) => {
                if (err) reject(err);
                else resolve(results);
            });
        });
        
        if (teamResult.length === 0) {
            return res.status(404).json({ error: 'Team not found' });
        }
        
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        const isTeamCaptain = teamResult[0].CaptainID == currentUserID;
        const isAdmin = userClassification?.UserType === 'Admin User';
        
        if (!isTeamCaptain && !isAdmin) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only team captain or admins can update team details'
            });
        }
        
        // Build update query
        const updates = [];
        const values = [];
        
        if (TeamName) { updates.push('TeamName = ?'); values.push(TeamName); }
        if (Description) { updates.push('Description = ?'); values.push(Description); }
        if (SportID) { updates.push('SportID = ?'); values.push(SportID); }
        
        if (updates.length === 0) {
            return res.status(400).json({ error: 'No valid fields to update' });
        }
        
        values.push(teamID);
        
        db.query(
            `UPDATE Teams SET ${updates.join(', ')} WHERE TeamID = ?`,
            values,
            (err, result) => {
                if(err) return res.status(500).json({ error: err });
                
                res.json({ 
                    message: 'Team updated successfully',
                    updatedBy: isTeamCaptain ? 'Team Captain' : 'Admin',
                    updatedFields: updates.length
                });
            }
        );
    } catch (error) {
        console.error('Update team error:', error);
        res.status(500).json({ error: 'Failed to update team' });
    }
});

// DELETE team (only admins can delete teams)
router.delete('/delete/:id', async (req, res) => {
    try {
        const teamID = req.params.id;
        const currentUserID = req.userID || req.headers['user-id'] || req.query.userId;
        
        if (!currentUserID) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        
        // Only admins can delete teams
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        if (userClassification?.UserType !== 'Admin User') {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only admins can delete teams'
            });
        }
        
        // Check if team has active matches or bookings
        const activeCheck = await new Promise((resolve, reject) => {
            db.query(`
                SELECT COUNT(*) as activeCount FROM (
                    SELECT MatchID FROM Matches WHERE (Team1ID = ? OR Team2ID = ?) AND MatchDate > NOW()
                    UNION
                    SELECT BookingID FROM Bookings b 
                    JOIN TeamMembers tm ON b.UserID = tm.UserID 
                    WHERE tm.TeamID = ? AND b.BookingDate > NOW()
                ) as active
            `, [teamID, teamID, teamID], (err, results) => {
                if (err) reject(err);
                else resolve(results[0].activeCount);
            });
        });
        
        if (activeCheck > 0) {
            return res.status(400).json({ 
                error: 'Cannot delete team', 
                message: 'Team has active matches or bookings. Please resolve these first.'
            });
        }
        
        // Delete team members first (foreign key constraint)
        db.query('DELETE FROM TeamMembers WHERE TeamID = ?', [teamID], (err) => {
            if (err) return res.status(500).json({ error: 'Failed to remove team members' });
            
            // Delete the team
            db.query('DELETE FROM Teams WHERE TeamID = ?', [teamID], (err, result) => {
                if(err) return res.status(500).json({ error: err });
                if(result.affectedRows === 0) return res.status(404).json({ error: 'Team not found' });
                
                // Log the deletion
                PermissionManager.logActivity(
                    currentUserID, 'DELETE', 'Teams', teamID, 
                    `Team deleted by admin`
                );
                
                res.json({ 
                    message: 'Team deleted successfully',
                    deletedBy: userClassification.Name
                });
            });
        });
    } catch (error) {
        console.error('Delete team error:', error);
        res.status(500).json({ error: 'Failed to delete team' });
    }
});

// POST join team (only players can join teams)
router.post('/join/:id', checkPermission('TeamMembers', 'INSERT'), async (req, res) => {
    try {
        const teamID = req.params.id;
        const currentUserID = req.userID;
        
        // Check if user is a player
        const userClassification = await PermissionManager.getUserClassification(currentUserID);
        if (userClassification.RoleID !== 1) {
            return res.status(403).json({ 
                error: 'Access denied', 
                message: 'Only players can join teams'
            });
        }
        
        // Check if team exists
        const teamExists = await new Promise((resolve, reject) => {
            db.query('SELECT TeamID, TeamName FROM Teams WHERE TeamID = ?', [teamID], (err, results) => {
                if (err) reject(err);
                else resolve(results);
            });
        });
        
        if (teamExists.length === 0) {
            return res.status(404).json({ error: 'Team not found' });
        }
        
        // Check if user is already a member
        db.query('SELECT MemberID FROM TeamMembers WHERE TeamID = ? AND UserID = ?', 
            [teamID, currentUserID], (err, existing) => {
            if (err) return res.status(500).json({ error: err });
            if (existing.length > 0) {
                return res.status(409).json({ 
                    error: 'Already a member', 
                    message: 'You are already a member of this team'
                });
            }
            
            // Add user to team
            db.query(
                'INSERT INTO TeamMembers (TeamID, UserID, JoinDate) VALUES (?, ?, NOW())',
                [teamID, currentUserID],
                (err, result) => {
                    if(err) return res.status(500).json({ error: err });
                    
                    // Log the activity
                    PermissionManager.logActivity(
                        currentUserID, 'INSERT', 'TeamMembers', result.insertId, 
                        `Joined team: ${teamExists[0].TeamName}`
                    );
                    
                    res.status(201).json({ 
                        message: 'Successfully joined team',
                        teamName: teamExists[0].TeamName,
                        memberID: result.insertId
                    });
                }
            );
        });
    } catch (error) {
        console.error('Join team error:', error);
        res.status(500).json({ error: 'Failed to join team' });
    }
});

// DELETE leave team (players can leave teams they're members of)
router.delete('/leave/:id', checkPermission('TeamMembers', 'DELETE'), async (req, res) => {
    try {
        const teamID = req.params.id;
        const currentUserID = req.userID;
        
        // Check if user is a team member
        const memberResult = await new Promise((resolve, reject) => {
            db.query(`
                SELECT tm.MemberID, t.TeamName, t.CaptainID 
                FROM TeamMembers tm 
                JOIN Teams t ON tm.TeamID = t.TeamID 
                WHERE tm.TeamID = ? AND tm.UserID = ?
            `, [teamID, currentUserID], (err, results) => {
                if (err) reject(err);
                else resolve(results);
            });
        });
        
        if (memberResult.length === 0) {
            return res.status(404).json({ 
                error: 'Not a member', 
                message: 'You are not a member of this team'
            });
        }
        
        const member = memberResult[0];
        
        // Prevent captain from leaving (they need to transfer captaincy first)
        if (member.CaptainID == currentUserID) {
            return res.status(400).json({ 
                error: 'Cannot leave team', 
                message: 'Team captain cannot leave. Transfer captaincy first or delete the team.'
            });
        }
        
        // Remove user from team
        db.query('DELETE FROM TeamMembers WHERE MemberID = ?', [member.MemberID], (err, result) => {
            if(err) return res.status(500).json({ error: err });
            
            // Log the activity
            PermissionManager.logActivity(
                currentUserID, 'DELETE', 'TeamMembers', member.MemberID, 
                `Left team: ${member.TeamName}`
            );
            
            res.json({ 
                message: 'Successfully left team',
                teamName: member.TeamName
            });
        });
    } catch (error) {
        console.error('Leave team error:', error);
        res.status(500).json({ error: 'Failed to leave team' });
    }
});

// GET user's teams
router.get('/user/:userID', checkPermission('Teams', 'SELECT'), (req, res) => {
    const userID = req.params.userID;
    
    db.query(`
        SELECT t.*, s.SportName, 
               CASE WHEN t.CaptainID = ? THEN 'Captain' ELSE 'Member' END as Role
        FROM Teams t
        JOIN TeamMembers tm ON t.TeamID = tm.TeamID
        JOIN Sports s ON t.SportID = s.SportID
        WHERE tm.UserID = ?
        ORDER BY t.CreatedAt DESC
    `, [userID, userID], (err, results) => {
        if(err) return res.status(500).json({ error: err });
        
        res.json({
            userID: userID,
            teams: results,
            total: results.length,
            message: 'User teams retrieved successfully'
        });
    });
});

module.exports = router;