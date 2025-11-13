
## Team Creation Queries

### 1. Create New Team Query
**File:** `playo-backend/routes/teams.js` (Line ~90)
**Website Feature:** "Create Team" form on teams.html page

```sql
INSERT INTO Teams (TeamName, CaptainID, SportID, MaxMembers, Description, CreatedAt)
VALUES (?, ?, ?, ?, ?, NOW())
```

**Explanation:**
- Handles team creation when users fill out the "Create New Team" form
- Automatically sets the creator as the team captain (CaptainID)
- Associates team with a specific sport (SportID)
- Sets maximum team size limit (MaxMembers)
- Records team description and creation timestamp

**Parameters:**
- `TeamName`: User-entered team name
- `CaptainID`: Current user's ID (from JWT token)
- `SportID`: Selected sport from dropdown
- `MaxMembers`: Team size limit (default 11)
- `Description`: Optional team description

---

### 2. Add Captain as First Team Member Query
**File:** `playo-backend/routes/teams.js` (Line ~100)
**Website Feature:** Automatic captain enrollment after team creation

```sql
INSERT INTO TeamMembers (TeamID, UserID, Role, JoinedAt, Status)
VALUES (?, ?, 'Captain', NOW(), 'Active')
```

**Explanation:**
- Automatically adds the team creator as the first team member with 'Captain' role
- Ensures every team has at least one active member
- Sets captain status to 'Active' immediately upon team creation

**Parameters:**
- `TeamID`: ID of newly created team
- `UserID`: Team captain's user ID
- `Role`: Always 'Captain' for this query
- `Status`: Always 'Active'

---

## Team Retrieval Queries

### 3. Get All Teams with Details Query
**File:** `playo-backend/routes/teams.js` (Line ~40)
**Website Feature:** Teams listing page, team browser, team selection dropdowns

```sql
SELECT 
    t.TeamID,
    t.TeamName,
    t.Description,
    t.MaxMembers,
    t.CreatedAt,
    u.Name as CaptainName,
    u.Email as CaptainEmail,
    s.SportName,
    s.Category as SportCategory,
    COUNT(tm.UserID) as CurrentMembers
FROM Teams t
LEFT JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.Status = 'Active'
GROUP BY t.TeamID, t.TeamName, t.Description, t.MaxMembers, t.CreatedAt, 
         u.Name, u.Email, s.SportName, s.Category
ORDER BY t.CreatedAt DESC
```

**Explanation:**
- Displays complete team information on teams.html page
- Shows captain details for each team
- Includes sport information and category
- Counts active members to show "5/11 members" type displays
- Orders by newest teams first for better user experience

**Used in Website Features:**
- Main teams listing page
- Team selection dropdowns in match creation
- Team browser for players looking to join
- Admin dashboard team overview

---

### 4. Get User's Teams Query
**File:** `playo-backend/routes/teams.js` (Line ~120)
**Website Feature:** "My Teams" section in player dashboard

```sql
SELECT 
    t.TeamID,
    t.TeamName,
    t.Description,
    t.MaxMembers,
    tm.Role,
    tm.JoinedAt,
    tm.Status,
    s.SportName,
    u.Name as CaptainName,
    COUNT(tm2.UserID) as TotalMembers
FROM Teams t
INNER JOIN TeamMembers tm ON t.TeamID = tm.TeamID
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN TeamMembers tm2 ON t.TeamID = tm2.TeamID AND tm2.Status = 'Active'
WHERE tm.UserID = ? AND tm.Status IN ('Active', 'Pending')
GROUP BY t.TeamID, t.TeamName, t.Description, t.MaxMembers, tm.Role, 
         tm.JoinedAt, tm.Status, s.SportName, u.Name
ORDER BY tm.JoinedAt DESC
```

**Explanation:**
- Shows all teams a user belongs to or has pending invitations for
- Displays user's role in each team (Captain, Member, etc.)
- Shows join date and current membership status
- Used in player dashboard to manage user's team memberships

**Parameters:**
- `UserID`: Current logged-in user's ID (from JWT token)

---

### 5. Get Team by ID with Full Details Query
**File:** `playo-backend/routes/teams.js` (Line ~180)
**Website Feature:** Team detail modal, team profile pages

```sql
SELECT 
    t.*,
    u.Name as CaptainName,
    u.Email as CaptainEmail,
    u.PhoneNumber as CaptainPhone,
    s.SportName,
    s.Category as SportCategory,
    s.PlayersPerTeam,
    COUNT(tm.UserID) as TotalMembers
FROM Teams t
LEFT JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.Status = 'Active'
WHERE t.TeamID = ?
GROUP BY t.TeamID
```

**Explanation:**
- Retrieves complete information for a specific team
- Used when clicking "View Team Details" buttons
- Provides captain contact information
- Shows sport-specific details like players per team requirement

**Parameters:**
- `TeamID`: ID of the team to view

---

## Team Member Management Queries

### 6. Get Team Members List Query
**File:** `playo-backend/routes/teamMembers.js` (Line ~50)
**Website Feature:** Team member list in team details modal

```sql
SELECT 
    tm.TeamMemberID,
    tm.TeamID,
    tm.UserID,
    tm.Role,
    tm.JoinedAt,
    tm.Status,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.Gender
FROM TeamMembers tm
LEFT JOIN Users u ON tm.UserID = u.UserID
WHERE tm.TeamID = ?
ORDER BY 
    CASE tm.Role 
        WHEN 'Captain' THEN 1 
        WHEN 'Vice Captain' THEN 2 
        ELSE 3 
    END,
    tm.JoinedAt ASC
```

**Explanation:**
- Shows all members of a specific team
- Orders by role hierarchy (Captain first, then Vice Captain, then regular members)
- Includes member contact information and status
- Used in team management interface for captains

**Parameters:**
- `TeamID`: ID of the team whose members to display

---

### 7. Add New Team Member Query
**File:** `playo-backend/routes/teamMembers.js` (Line ~90)
**Website Feature:** "Join Team" functionality, invite system

```sql
INSERT INTO TeamMembers (TeamID, UserID, Role, JoinedAt, Status)
VALUES (?, ?, ?, NOW(), ?)
```

**Explanation:**
- Adds new members to teams
- Handles both direct joins and invitation acceptances
- Sets appropriate role (usually 'Member' for new joins)
- Status can be 'Active' for direct joins or 'Pending' for invitations

**Parameters:**
- `TeamID`: ID of team to join
- `UserID`: ID of user joining the team
- `Role`: Usually 'Member', can be 'Vice Captain' if promoted
- `Status`: 'Active' or 'Pending' based on join method

---

### 8. Check Team Capacity Query
**File:** `playo-backend/routes/teamMembers.js` (Line ~75)
**Website Feature:** Join validation, prevents overfull teams

```sql
SELECT 
    t.MaxMembers,
    COUNT(tm.UserID) as CurrentMembers
FROM Teams t
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.Status = 'Active'
WHERE t.TeamID = ?
GROUP BY t.TeamID, t.MaxMembers
```

**Explanation:**
- Checks if team has space for new members before allowing joins
- Prevents teams from exceeding their maximum capacity
- Used in join validation logic

**Parameters:**
- `TeamID`: ID of team to check capacity for

---

### 9. Check Duplicate Membership Query
**File:** `playo-backend/routes/teamMembers.js` (Line ~85)
**Website Feature:** Prevents users from joining same team twice

```sql
SELECT TeamMemberID 
FROM TeamMembers 
WHERE TeamID = ? AND UserID = ? AND Status IN ('Active', 'Pending')
```

**Explanation:**
- Ensures users cannot join the same team multiple times
- Checks for both active memberships and pending invitations
- Returns existing membership if found

**Parameters:**
- `TeamID`: ID of team being joined
- `UserID`: ID of user attempting to join

---

### 10. Update Member Role Query
**File:** `playo-backend/routes/teamMembers.js` (Line ~150)
**Website Feature:** Promote/demote team members (Captain functionality)

```sql
UPDATE TeamMembers 
SET Role = ? 
WHERE TeamMemberID = ? AND TeamID = ?
```

**Explanation:**
- Allows team captains to promote members to Vice Captain
- Handles role changes within team hierarchy
- Used in team management interface

**Parameters:**
- `Role`: New role ('Member', 'Vice Captain', etc.)
- `TeamMemberID`: ID of team member record to update
- `TeamID`: Team ID for security validation

---

### 11. Remove Team Member Query
**File:** `playo-backend/routes/teamMembers.js` (Line ~180)
**Website Feature:** "Leave Team" and "Remove Member" functionality

```sql
UPDATE TeamMembers 
SET Status = 'Inactive', LeftAt = NOW()
WHERE TeamMemberID = ? AND TeamID = ?
```

**Explanation:**
- Soft-deletes team memberships (maintains history)
- Records when member left the team
- Used for both voluntary leaves and captain removals

**Parameters:**
- `TeamMemberID`: ID of membership record to deactivate
- `TeamID`: Team ID for validation

---

## Team Update Queries

### 12. Update Team Information Query
**File:** `playo-backend/routes/teams.js` (Line ~220)
**Website Feature:** "Edit Team" functionality for captains

```sql
UPDATE Teams 
SET TeamName = ?, Description = ?, MaxMembers = ?, SportID = ?
WHERE TeamID = ? AND CaptainID = ?
```

**Explanation:**
- Allows team captains to modify team details
- Updates team name, description, member limit, and sport
- Includes captain validation to prevent unauthorized edits

**Parameters:**
- `TeamName`: Updated team name
- `Description`: Updated team description
- `MaxMembers`: Updated member limit
- `SportID`: Updated sport (if changing sport type)
- `TeamID`: ID of team being updated
- `CaptainID`: Captain's user ID for authorization

---

## Team Deletion Queries

### 13. Delete Team Query
**File:** `playo-backend/routes/teams.js` (Line ~280)
**Website Feature:** "Delete Team" functionality for captains

```sql
DELETE FROM Teams 
WHERE TeamID = ? AND CaptainID = ?
```

**Explanation:**
- Permanently removes team from database
- Only allows team captains to delete their teams
- Cascades to remove all team members and related data

**Parameters:**
- `TeamID`: ID of team to delete
- `CaptainID`: Captain's user ID for authorization

---

### 14. Cleanup Team Members Query
**File:** `playo-backend/routes/teams.js` (Line ~285)
**Website Feature:** Automatic cleanup when team is deleted

```sql
DELETE FROM TeamMembers 
WHERE TeamID = ?
```

**Explanation:**
- Removes all team member records when team is deleted
- Prevents orphaned records in TeamMembers table
- Executed automatically after team deletion

**Parameters:**
- `TeamID`: ID of deleted team

---

## Team Sports Integration Queries

### 15. Get Teams by Sport Query
**File:** `playo-backend/routes/teams.js` (Line ~320)
**Website Feature:** Sport-specific team filtering, match scheduling

```sql
SELECT 
    t.TeamID,
    t.TeamName,
    u.Name as CaptainName,
    COUNT(tm.UserID) as MemberCount
FROM Teams t
LEFT JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.Status = 'Active'
WHERE t.SportID = ?
GROUP BY t.TeamID, t.TeamName, u.Name
HAVING COUNT(tm.UserID) >= ?
ORDER BY t.TeamName
```

**Explanation:**
- Filters teams by specific sport for match creation
- Only shows teams with minimum required members
- Used in match scheduling dropdown menus
- Ensures only eligible teams can be selected for matches

**Parameters:**
- `SportID`: ID of sport to filter by
- Minimum member count: Usually from sports table (PlayersPerTeam)

---

### 16. Get Sports for Team Dropdown Query
**File:** `playo-backend/routes/sports.js` (Line ~30)
**Website Feature:** Sport selection dropdown in team creation

```sql
SELECT SportID, SportName, Category, PlayersPerTeam, Description
FROM Sports 
WHERE IsActive = 1
ORDER BY Category, SportName
```

**Explanation:**
- Populates sport dropdown when creating teams
- Only shows active sports
- Groups by category for better organization
- Shows required players per team for team size planning

---

## Team Match Integration Queries

### 17. Get Team's Upcoming Matches Query
**File:** `playo-backend/routes/matches.js` (Line ~150)
**Website Feature:** Team schedule view in team details

```sql
SELECT 
    m.MatchID,
    m.MatchDate,
    m.MatchTime,
    m.Status,
    v.VenueName,
    v.Address as VenueAddress,
    t1.TeamName as Team1Name,
    t2.TeamName as Team2Name,
    CASE 
        WHEN m.Team1ID = ? THEN t2.TeamName
        WHEN m.Team2ID = ? THEN t1.TeamName
    END as OpponentName
FROM Matches m
LEFT JOIN Venues v ON m.VenueID = v.VenueID
LEFT JOIN Teams t1 ON m.Team1ID = t1.TeamID
LEFT JOIN Teams t2 ON m.Team2ID = t2.TeamID
WHERE (m.Team1ID = ? OR m.Team2ID = ?) 
    AND m.MatchDate >= CURDATE()
    AND m.Status != 'Cancelled'
ORDER BY m.MatchDate, m.MatchTime
```

**Explanation:**
- Shows upcoming matches for a specific team
- Displays opponent team name and venue details
- Excludes past matches and cancelled matches
- Used in team dashboard and team detail views

**Parameters:**
- `TeamID`: ID of team to get matches for (used 4 times in query)

---

### 18. Team Match History Query
**File:** `playo-backend/routes/matches.js` (Line ~200)
**Website Feature:** Team match history, statistics

```sql
SELECT 
    m.MatchID,
    m.MatchDate,
    m.MatchTime,
    m.Status,
    m.WinnerTeamID,
    v.VenueName,
    CASE 
        WHEN m.Team1ID = ? THEN t2.TeamName
        WHEN m.Team2ID = ? THEN t1.TeamName
    END as OpponentName,
    CASE 
        WHEN m.WinnerTeamID = ? THEN 'Won'
        WHEN m.WinnerTeamID IS NOT NULL THEN 'Lost'
        ELSE 'Draw'
    END as Result
FROM Matches m
LEFT JOIN Venues v ON m.VenueID = v.VenueID
LEFT JOIN Teams t1 ON m.Team1ID = t1.TeamID
LEFT JOIN Teams t2 ON m.Team2ID = t2.TeamID
WHERE (m.Team1ID = ? OR m.Team2ID = ?) 
    AND m.MatchDate < CURDATE()
    AND m.Status = 'Completed'
ORDER BY m.MatchDate DESC, m.MatchTime DESC
```

**Explanation:**
- Shows completed matches for team statistics
- Calculates win/loss/draw results
- Displays match history in reverse chronological order
- Used for team performance tracking

**Parameters:**
- `TeamID`: ID of team to get history for (used 5 times in query)

---

## Advanced Team Queries

### 19. Team Statistics Query
**File:** `playo-backend/routes/teams.js` (Line ~350)
**Website Feature:** Team dashboard statistics, team profile

```sql
SELECT 
    t.TeamID,
    t.TeamName,
    COUNT(DISTINCT tm.UserID) as TotalMembers,
    COUNT(DISTINCT CASE WHEN m.Status = 'Completed' THEN m.MatchID END) as MatchesPlayed,
    COUNT(DISTINCT CASE WHEN m.WinnerTeamID = t.TeamID THEN m.MatchID END) as MatchesWon,
    COUNT(DISTINCT CASE WHEN m.Status = 'Completed' AND m.WinnerTeamID != t.TeamID AND m.WinnerTeamID IS NOT NULL THEN m.MatchID END) as MatchesLost,
    COUNT(DISTINCT CASE WHEN m.Status = 'Completed' AND m.WinnerTeamID IS NULL THEN m.MatchID END) as MatchesDrawn
FROM Teams t
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.Status = 'Active'
LEFT JOIN Matches m ON (t.TeamID = m.Team1ID OR t.TeamID = m.Team2ID)
WHERE t.TeamID = ?
GROUP BY t.TeamID, t.TeamName
```

**Explanation:**
- Calculates comprehensive team statistics
- Shows total members, matches played, won, lost, and drawn
- Used in team dashboard and profile pages
- Provides data for team performance analysis

**Parameters:**
- `TeamID`: ID of team to get statistics for

---

### 20. Search Teams Query
**File:** `playo-backend/routes/teams.js` (Line ~400)
**Website Feature:** Team search functionality on teams page

```sql
SELECT 
    t.TeamID,
    t.TeamName,
    t.Description,
    u.Name as CaptainName,
    s.SportName,
    COUNT(tm.UserID) as CurrentMembers,
    t.MaxMembers
FROM Teams t
LEFT JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.Status = 'Active'
WHERE (t.TeamName LIKE ? OR t.Description LIKE ? OR s.SportName LIKE ?)
GROUP BY t.TeamID, t.TeamName, t.Description, u.Name, s.SportName, t.MaxMembers
ORDER BY t.TeamName
```

**Explanation:**
- Enables users to search for teams by name, description, or sport
- Used in team browser with search functionality
- Helps players find teams to join based on interests
- Case-insensitive search across multiple fields

**Parameters:**
- Search term (used 3 times): Formatted with wildcards like `%searchTerm%`

---

## Database Triggers Related to Team Management

### 21. Team Captain Validation Trigger
**File:** `database/06_triggers.sql` (Line ~154)
**Website Feature:** Automatic validation during team creation

```sql
CREATE TRIGGER tr_team_captain_validation
BEFORE INSERT ON Teams
FOR EACH ROW
BEGIN
    DECLARE captain_role INT;
    
    -- Get captain's role
    SELECT RoleID INTO captain_role
    FROM Users WHERE UserID = NEW.CaptainID;
    
    -- Validate captain is a player
    IF captain_role != 1 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Team captain must be a player (RoleID = 1)';
    END IF;
END
```

**Explanation:**
- Automatically validates that team captain is a player (RoleID = 1) before team creation
- Prevents venue owners or admins from being team captains
- Fires before INSERT on Teams table to ensure data integrity
- Used when creating teams through "Create Team" form

**Integration with Team Management:**
- Works with Query #1 (Create New Team Query)
- Ensures business rule compliance automatically
- Prevents invalid team setups

---

### 22. Team Deletion Cleanup Trigger
**File:** `database/06_triggers.sql` (Line ~234)
**Website Feature:** Automatic cleanup when team is deleted

```sql
CREATE TRIGGER tr_team_delete_cleanup
BEFORE DELETE ON Teams
FOR EACH ROW
BEGIN
    -- Remove all team members
    DELETE FROM TeamMembers WHERE TeamID = OLD.TeamID;
    
    -- Log the deletion
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (OLD.CaptainID, 'DELETE', 'Teams', NOW());
END
```

**Explanation:**
- Automatically removes all team members when a team is deleted
- Creates audit trail of team deletion
- Prevents orphaned records in TeamMembers table
- Maintains data consistency during team deletion

**Integration with Team Management:**
- Works with Query #13 (Delete Team Query)
- Automatically handles cascading deletions
- Ensures complete cleanup of team-related data

---

### 23. Match Team Validation Triggers
**File:** `database/06_triggers.sql` (Line ~264)
**Website Feature:** Match creation validation for teams

```sql
-- Trigger: Validate match teams are different
CREATE TRIGGER tr_match_team_validation
BEFORE INSERT ON Matches
FOR EACH ROW
BEGIN
    IF NEW.Team1ID = NEW.Team2ID THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Team1 and Team2 must be different';
    END IF;
END

-- Trigger: Validate match teams play the same sport
CREATE TRIGGER tr_match_sport_validation
BEFORE INSERT ON Matches
FOR EACH ROW
BEGIN
    DECLARE team1_sport INT;
    DECLARE team2_sport INT;
    
    -- Get sports for both teams
    SELECT SportID INTO team1_sport FROM Teams WHERE TeamID = NEW.Team1ID;
    SELECT SportID INTO team2_sport FROM Teams WHERE TeamID = NEW.Team2ID;
    
    -- Validate same sport
    IF team1_sport != team2_sport THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Both teams must play the same sport';
    END IF;
END
```

**Explanation:**
- Prevents teams from playing against themselves
- Ensures both teams play the same sport in a match
- Validates match integrity before creation
- Used in match scheduling functionality

**Integration with Team Management:**
- Works with Query #17 and #18 (Match-related queries)
- Integrates with team sport filtering (Query #15)
- Ensures valid match setups

---

### 24. Match Team Notification Trigger
**File:** `database/06_triggers.sql` (Line ~290)
**Website Feature:** Automatic notifications for team captains

```sql
CREATE TRIGGER tr_match_team_notification
AFTER INSERT ON Matches
FOR EACH ROW
BEGIN
    DECLARE team1_captain INT;
    DECLARE team2_captain INT;
    DECLARE notification_msg TEXT;
    
    -- Get team captains
    SELECT CaptainID INTO team1_captain FROM Teams WHERE TeamID = NEW.Team1ID;
    SELECT CaptainID INTO team2_captain FROM Teams WHERE TeamID = NEW.Team2ID;
    
    SET notification_msg = CONCAT('Match scheduled: ', NEW.MatchTitle, ' on ', NEW.MatchDate, ' at ', NEW.MatchTime);
    
    -- Notify both captains
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (team1_captain, notification_msg, FALSE);
    
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (team2_captain, notification_msg, FALSE);
END
```

**Explanation:**
- Automatically notifies team captains when matches are scheduled
- Creates notifications for both teams involved in the match
- Improves communication and match awareness
- Fires after match creation

**Integration with Team Management:**
- Connects teams with match scheduling system
- Enhances team captain workflow
- Supports team communication features

---

## Stored Procedures Related to Team Management

### 25. Create Team Procedure
**File:** `database/05_procedures.sql` (Line ~330) | Used in: `playo-backend/routes/teams.js` (Line ~222)
**Website Feature:** Team creation with validation and automatic member addition

```sql
CREATE PROCEDURE CreateTeam(
    IN p_team_name VARCHAR(150),
    IN p_sport_id INT,
    IN p_captain_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate captain is a player
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = p_captain_id AND RoleID = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid captain - must be a player';
    END IF;
    
    -- Create team
    INSERT INTO Teams (TeamName, SportID, CaptainID)
    VALUES (p_team_name, p_sport_id, p_captain_id);
    
    SET @team_id = LAST_INSERT_ID();
    
    -- Add captain as team member
    INSERT INTO TeamMembers (TeamID, UserID, JoinedDate)
    VALUES (@team_id, p_captain_id, CURDATE());
    
    -- Create notification for captain
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (p_captain_id, CONCAT('Team "', p_team_name, '" created successfully!'), FALSE);
    
    COMMIT;
    
    SELECT 'Team created successfully!' as Message, @team_id as TeamID;
END
```

**Backend Usage:**
```javascript
// In routes/teams.js
const [result] = await connection.execute(
    'CALL CreateTeam(?, ?, ?)',
    [teamName, sportId, captainId]
);
```

**Explanation:**
- Handles complete team creation process in a single atomic transaction
- Validates captain role before creating team
- Automatically adds captain as first team member
- Creates success notification for captain
- Ensures data consistency with transaction handling

**Integration with Team Management:**
- Replaces Query #1 and #2 with single atomic operation
- Used in "Create Team" form functionality
- Ensures proper team initialization

---

### 26. Join Team Procedure
**File:** `database/05_procedures.sql` (Line ~370)
**Website Feature:** Team joining with validation and notifications

```sql
CREATE PROCEDURE JoinTeam(
    IN p_team_id INT,
    IN p_user_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if team exists
    IF NOT EXISTS (SELECT 1 FROM Teams WHERE TeamID = p_team_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team not found';
    END IF;
    
    -- Check if user is a player
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = p_user_id AND RoleID = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only players can join teams';
    END IF;
    
    -- Check if already a member
    IF EXISTS (SELECT 1 FROM TeamMembers WHERE TeamID = p_team_id AND UserID = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Already a member of this team';
    END IF;
    
    -- Add team member
    INSERT INTO TeamMembers (TeamID, UserID, JoinedDate)
    VALUES (p_team_id, p_user_id, CURDATE());
    
    -- Create notification
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (p_user_id, 'You have successfully joined the team!', FALSE);
    
    COMMIT;
    
    SELECT 'Successfully joined team!' as Message;
END
```

**Explanation:**
- Validates team exists and user is eligible to join
- Prevents duplicate memberships
- Adds user as team member with proper date tracking
- Creates success notification
- Handles all validations in single transaction

**Integration with Team Management:**
- Enhances Query #7 (Add New Team Member Query)
- Combines validation queries (#8, #9) into single procedure
- Used in "Join Team" functionality

---

### 27. Get Player Activity Procedure
**File:** `database/05_procedures.sql` (Line ~490)
**Website Feature:** Player dashboard statistics and activity summary

```sql
CREATE PROCEDURE GetPlayerActivity(
    IN p_user_id INT
)
BEGIN
    SELECT 
        'Teams' as Category,
        COUNT(tm.TeamID) as Count,
        GROUP_CONCAT(t.TeamName SEPARATOR ', ') as Details
    FROM TeamMembers tm
    INNER JOIN Teams t ON tm.TeamID = t.TeamID
    WHERE tm.UserID = p_user_id
    
    UNION ALL
    
    SELECT 
        'Bookings' as Category,
        COUNT(b.BookingID) as Count,
        CONCAT('Total Spent: ₹', COALESCE(SUM(b.TotalAmount), 0)) as Details
    FROM Bookings b
    WHERE b.UserID = p_user_id
    
    UNION ALL
    
    SELECT 
        'Matches' as Category,
        COUNT(DISTINCT m.MatchID) as Count,
        'Upcoming and completed matches' as Details
    FROM Matches m
    INNER JOIN Teams t ON (m.Team1ID = t.TeamID OR m.Team2ID = t.TeamID)
    INNER JOIN TeamMembers tm ON t.TeamID = tm.TeamID
    WHERE tm.UserID = p_user_id;
END
```

**Explanation:**
- Provides comprehensive activity summary for a player
- Shows team memberships, booking history, and match participation
- Returns unified format for dashboard display
- Combines multiple complex queries into single call

**Integration with Team Management:**
- Enhances Query #4 (Get User's Teams Query)
- Provides data for player dashboard statistics
- Integrates team data with other user activities

---

## Advanced Team Management Features

### 28. Team Statistics Complex Query
**Enhancement of Query #19** - Can be implemented as a procedure for better performance

```sql
-- Advanced team statistics with win rates and member activity
CREATE PROCEDURE GetAdvancedTeamStats(
    IN p_team_id INT
)
BEGIN
    SELECT 
        t.TeamID,
        t.TeamName,
        t.CreatedAt as TeamAge,
        s.SportName,
        COUNT(DISTINCT tm.UserID) as TotalMembers,
        COUNT(DISTINCT CASE WHEN m.Status = 'Completed' THEN m.MatchID END) as MatchesPlayed,
        COUNT(DISTINCT CASE WHEN m.WinnerTeamID = t.TeamID THEN m.MatchID END) as MatchesWon,
        COUNT(DISTINCT CASE WHEN m.Status = 'Completed' AND m.WinnerTeamID != t.TeamID AND m.WinnerTeamID IS NOT NULL THEN m.MatchID END) as MatchesLost,
        COUNT(DISTINCT CASE WHEN m.Status = 'Completed' AND m.WinnerTeamID IS NULL THEN m.MatchID END) as MatchesDrawn,
        ROUND(
            (COUNT(DISTINCT CASE WHEN m.WinnerTeamID = t.TeamID THEN m.MatchID END) * 100.0) / 
            NULLIF(COUNT(DISTINCT CASE WHEN m.Status = 'Completed' THEN m.MatchID END), 0), 2
        ) as WinPercentage,
        AVG(DATEDIFF(CURDATE(), tm.JoinedAt)) as AvgMemberTenure
    FROM Teams t
    LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.Status = 'Active'
    LEFT JOIN Sports s ON t.SportID = s.SportID
    LEFT JOIN Matches m ON (t.TeamID = m.Team1ID OR t.TeamID = m.Team2ID)
    WHERE t.TeamID = p_team_id
    GROUP BY t.TeamID, t.TeamName, t.CreatedAt, s.SportName;
END
```

**Explanation:**
- Advanced analytics for team performance tracking
- Calculates win percentage, average member tenure
- Provides comprehensive team metrics for dashboards
- Can replace or enhance basic team statistics query

---