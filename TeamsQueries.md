## Team Creation Queries:
### 1. Create New Team Query:
```sql
INSERT INTO Teams (TeamName, CaptainID, SportID, MaxMembers, Description, CreatedAt)
VALUES (?, ?, ?, ?, ?, NOW())
```

### 2. Team Captain Validation (Handled by a trigger):
```sql
DELIMITER //

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
END //

DELIMITER ;
```

### 3. Add Team Creater as the Captain and First Member: 
```sql
DELIMITER //

CREATE TRIGGER tr_team_add_captain_member
AFTER INSERT ON Teams
FOR EACH ROW
BEGIN
    INSERT INTO TeamMembers (TeamID, UserID, JoinedDate)
    VALUES (NEW.TeamID, NEW.CaptainID, NOW());
END //

DELIMITER ;
```


## Reading Team Data Queries:
### 1. Teams that the user is part of (Shown in Dashboard): 
```sql
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
```

### 2. Every Team that exists in the database at the moment (Shown in My Teams WebPage):
```sql
SELECT 
    t.TeamID, 
    t.TeamName, 
    s.SportName as Sport,
    t.SportID,
    u.Name as CaptainName,
    u.UserID as CaptainID,
    u.Email as CaptainEmail,
    (SELECT COUNT(*) FROM TeamMembers tm WHERE tm.TeamID = t.TeamID) as MemberCount,
    (SELECT COUNT(*) 
     FROM TeamMembers tm 
     JOIN Users um ON tm.UserID = um.UserID 
     WHERE tm.TeamID = t.TeamID AND um.Gender = 'Male') as MaleMembers,
    (SELECT COUNT(*) 
     FROM TeamMembers tm 
     JOIN Users um ON tm.UserID = um.UserID 
     WHERE tm.TeamID = t.TeamID AND um.Gender = 'Female') as FemaleMembers
FROM Teams t
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Users u ON t.CaptainID = u.UserID
ORDER BY t.TeamName
```

### 3. Searching by the filters: 
```sql
SELECT 
    t.TeamID, 
    t.TeamName, 
    s.SportName as Sport,
    t.SportID,
    u.Name as CaptainName,
    u.UserID as CaptainID,
    (SELECT COUNT(*) FROM TeamMembers tm WHERE tm.TeamID = t.TeamID) as MemberCount,
    (SELECT COUNT(*) 
     FROM TeamMembers tm 
     JOIN Users um ON tm.UserID = um.UserID 
     WHERE tm.TeamID = t.TeamID AND um.Gender = 'Male') as MaleMembers,
    (SELECT COUNT(*) 
     FROM TeamMembers tm 
     JOIN Users um ON tm.UserID = um.UserID 
     WHERE tm.TeamID = t.TeamID AND um.Gender = 'Female') as FemaleMembers
FROM Teams t
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Users u ON t.CaptainID = u.UserID
WHERE 1=1
AND (? IS NULL OR t.SportID = ?)  -- Sport filter
AND (? = '' OR t.TeamName LIKE CONCAT('%', ?, '%'))  -- Search filter
AND (
    ? = 'all'  -- All compositions
    OR (? = 'All Male' AND 
        (SELECT COUNT(*) FROM TeamMembers tm JOIN Users um ON tm.UserID = um.UserID 
         WHERE tm.TeamID = t.TeamID AND um.Gender = 'Female') = 0
        AND (SELECT COUNT(*) FROM TeamMembers tm JOIN Users um ON tm.UserID = um.UserID 
             WHERE tm.TeamID = t.TeamID AND um.Gender = 'Male') > 0)
    OR (? = 'All Female' AND 
        (SELECT COUNT(*) FROM TeamMembers tm JOIN Users um ON tm.UserID = um.UserID 
         WHERE tm.TeamID = t.TeamID AND um.Gender = 'Male') = 0
        AND (SELECT COUNT(*) FROM TeamMembers tm JOIN Users um ON tm.UserID = um.UserID 
             WHERE tm.TeamID = t.TeamID AND um.Gender = 'Female') > 0)
    OR (? = 'Mixed' AND 
        (SELECT COUNT(*) FROM TeamMembers tm JOIN Users um ON tm.UserID = um.UserID 
         WHERE tm.TeamID = t.TeamID AND um.Gender = 'Male') > 0
        AND (SELECT COUNT(*) FROM TeamMembers tm JOIN Users um ON tm.UserID = um.UserID 
             WHERE tm.TeamID = t.TeamID AND um.Gender = 'Female') > 0)
)
ORDER BY t.TeamName
```

### 4. Fetching Team Members from a Single Team:
```sql
DELIMITER //

CREATE PROCEDURE GetTeamMembers(IN teamId INT)
BEGIN
    SELECT 
        u.UserID,
        u.Name as MemberName,
        u.Email,
        u.PhoneNumber,
        u.Gender,
        u.Address,
        tm.JoinedDate,
        CASE 
            WHEN u.UserID = t.CaptainID
            THEN 'Captain'
            ELSE 'Member'
        END as Role
    FROM TeamMembers tm
    JOIN Users u ON tm.UserID = u.UserID
    JOIN Teams t ON tm.TeamID = t.TeamID
    WHERE tm.TeamID = teamId
    ORDER BY 
        CASE WHEN u.UserID = t.CaptainID THEN 0 ELSE 1 END,
        tm.JoinedDate;
END //

DELIMITER ;
```

## Team Updating
### 1. Checking Permission (If Player is Captain or not):
```sql
SELECT * FROM Teams WHERE TeamID = ? AND CaptainID = ?
```

### 2. Editing the team (Update Query):
```sql
UPDATE Teams SET TeamName = ?, SportID = ? WHERE TeamID = ?
```

### 3. Validating to check if conflict exists with existing teams for same sport:
```sql
DELIMITER //

CREATE TRIGGER tr_team_name_validation
BEFORE UPDATE ON Teams
FOR EACH ROW
BEGIN
    -- Check if team name conflicts with existing teams for same sport
    IF NEW.TeamName != OLD.TeamName OR NEW.SportID != OLD.SportID THEN
        IF EXISTS (
            SELECT 1 FROM Teams 
            WHERE TeamName = NEW.TeamName 
            AND SportID = NEW.SportID 
            AND TeamID != NEW.TeamID
        ) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'A team with this name already exists for this sport';
        END IF;
    END IF;
    
    -- Check if sport exists
    IF NEW.SportID != OLD.SportID THEN
        IF NOT EXISTS (SELECT 1 FROM Sports WHERE SportID = NEW.SportID) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Sport not found';
        END IF;
    END IF;
END //

DELIMITER ;
```

### 4. Joining Another Team you are not part of :
#### i. Checking if team exists:
```sql
SELECT TeamID, TeamName, CaptainID, SportID
FROM Teams
WHERE TeamID = ?
```

#### ii. Checking if user is already a member:
```sql
SELECT TeamID, UserID
FROM TeamMembers
WHERE TeamID = ? AND UserID = ?
```

#### iii. Checking if user is captain:
```sql
SELECT CaptainID
FROM Teams
WHERE TeamID = ? AND CaptainID = ?
```

#### iv. Add user as team member:
```sql
INSERT INTO TeamMembers (TeamID, UserID, JoinedDate)
VALUES (?, ?, NOW())
```

## Team Deletion
### 1. Checking if user is captain:
```sql
SELECT * FROM Teams WHERE TeamID = ? AND CaptainID = ?
```

### 2. Checking if the team has any active matches:
```sql
SELECT MatchID 
FROM Matches 
WHERE (Team1ID = ? OR Team2ID = ?) 
AND MatchStatus != 'Completed' 
AND MatchStatus != 'Cancelled'
```

### 3. Deleting the Team members and Logging the team deletion (handled by trigger):
```sql
DELIMITER //

CREATE TRIGGER tr_team_delete_cleanup
BEFORE DELETE ON Teams
FOR EACH ROW
BEGIN
    -- Remove all team members
    DELETE FROM TeamMembers WHERE TeamID = OLD.TeamID;
    
    -- Log the deletion
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (OLD.CaptainID, 'DELETE', 'Teams', NOW());
END //

DELIMITER ;
```

### 4. Delete Team:
```sql
DELETE FROM Teams WHERE TeamID = ?
```

---

## Match Management (Team Competition)
### 1. Create New Match:
```sql
INSERT INTO Matches (MatchTitle, Team1ID, Team2ID, VenueID, MatchDate, MatchTime, Team1Score, Team2Score, MatchStatus)
VALUES (?, ?, ?, ?, ?, ?, 0, 0, 'Scheduled')
```

### 2. Validate Teams are Different (Trigger):
```sql
DELIMITER //

CREATE TRIGGER tr_match_team_validation
BEFORE INSERT ON Matches
FOR EACH ROW
BEGIN
    IF NEW.Team1ID = NEW.Team2ID THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Team1 and Team2 must be different';
    END IF;
END //

DELIMITER ;
```

### 3. Validate Teams Play Same Sport (Trigger):
```sql
DELIMITER //

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
END //

DELIMITER ;
```

### 4. Notify Team Captains of New Match (Trigger):
```sql
DELIMITER //

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
END //

DELIMITER ;
```

## Reading Match Data Queries:
### 1. All Matches with Complete Details (Using View):
```sql
-- Using match_details view for pre-joined data
SELECT 
    MatchID, 
    MatchTitle,
    Team1Name as Team1, 
    Team2Name as Team2,
    VenueName as Venue,
    MatchDate,
    MatchTime,
    MatchStatus as Status,
    Team1Score,
    Team2Score,
    Winner,
    SportName,
    VenueLocation,
    VenueCity,
    CASE 
        WHEN MatchStatus = 'Completed' AND Team1Score > Team2Score THEN 'Team1 Won'
        WHEN MatchStatus = 'Completed' AND Team2Score > Team1Score THEN 'Team2 Won'
        WHEN MatchStatus = 'Completed' AND Team1Score = Team2Score THEN 'Draw'
        ELSE NULL
    END as Result
FROM match_details
ORDER BY MatchDate DESC, MatchTime DESC
```

### 2. Matches for Specific Team:
```sql
SELECT 
    m.MatchID,
    m.MatchTitle,
    m.MatchDate,
    m.MatchTime,
    m.MatchStatus,
    CASE 
        WHEN m.Team1ID = ? THEN t2.TeamName
        ELSE t1.TeamName
    END as OpponentTeam,
    CASE 
        WHEN m.Team1ID = ? THEN m.Team1Score
        ELSE m.Team2Score
    END as OurScore,
    CASE 
        WHEN m.Team1ID = ? THEN m.Team2Score
        ELSE m.Team1Score
    END as OpponentScore,
    v.VenueName,
    v.Location as VenueLocation
FROM Matches m
LEFT JOIN Teams t1 ON m.Team1ID = t1.TeamID
LEFT JOIN Teams t2 ON m.Team2ID = t2.TeamID
LEFT JOIN Venues v ON m.VenueID = v.VenueID
WHERE m.Team1ID = ? OR m.Team2ID = ?
ORDER BY m.MatchDate DESC, m.MatchTime DESC
```

### 3. Upcoming Matches:
```sql
SELECT 
    MatchID,
    MatchTitle,
    Team1Name,
    Team2Name,
    VenueName,
    MatchDate,
    MatchTime,
    SportName
FROM match_details
WHERE MatchStatus = 'Scheduled'
  AND MatchDate >= CURDATE()
ORDER BY MatchDate ASC, MatchTime ASC
```

### 4. Completed Matches with Results:
```sql
SELECT 
    MatchID,
    MatchTitle,
    Team1Name,
    Team2Name,
    Team1Score,
    Team2Score,
    Winner,
    VenueName,
    MatchDate,
    MatchTime,
    SportName
FROM match_details
WHERE MatchStatus = 'Completed'
ORDER BY MatchDate DESC, MatchTime DESC
```

### 5. Single Match Details:
```sql
SELECT 
    m.*,
    t1.TeamName as Team1Name,
    t1.CaptainID as Team1CaptainID,
    u1.Name as Team1CaptainName,
    t2.TeamName as Team2Name,
    t2.CaptainID as Team2CaptainID,
    u2.Name as Team2CaptainName,
    v.VenueName,
    v.Location as VenueLocation,
    v.Address as VenueAddress,
    v.ContactNumber as VenueContact,
    s.SportName,
    CASE 
        WHEN m.MatchStatus = 'Completed' AND m.Team1Score > m.Team2Score THEN t1.TeamName
        WHEN m.MatchStatus = 'Completed' AND m.Team2Score > m.Team1Score THEN t2.TeamName
        WHEN m.MatchStatus = 'Completed' AND m.Team1Score = m.Team2Score THEN 'Draw'
        ELSE NULL
    END as Winner
FROM Matches m
LEFT JOIN Teams t1 ON m.Team1ID = t1.TeamID
LEFT JOIN Teams t2 ON m.Team2ID = t2.TeamID
LEFT JOIN Users u1 ON t1.CaptainID = u1.UserID
LEFT JOIN Users u2 ON t2.CaptainID = u2.UserID
LEFT JOIN Venues v ON m.VenueID = v.VenueID
LEFT JOIN Sports s ON t1.SportID = s.SportID
WHERE m.MatchID = ?
```

## Match Update Queries:
### 1. Update Match Status:
```sql
UPDATE Matches 
SET MatchStatus = ? 
WHERE MatchID = ?
```

### 2. Update Match Scores:
```sql
UPDATE Matches 
SET Team1Score = ?, 
    Team2Score = ?, 
    MatchStatus = 'Completed' 
WHERE MatchID = ?
```

### 3. Update Complete Match Information:
```sql
UPDATE Matches 
SET MatchTitle = ?,
    Team1ID = ?,
    Team2ID = ?,
    VenueID = ?,
    MatchDate = ?,
    MatchTime = ?,
    Team1Score = ?,
    Team2Score = ?,
    MatchStatus = ?
WHERE MatchID = ?
```

### 4. Reschedule Match:
```sql
UPDATE Matches 
SET MatchDate = ?, 
    MatchTime = ?, 
    VenueID = ? 
WHERE MatchID = ? 
  AND MatchStatus = 'Scheduled'
```

## Match Deletion Queries:
### 1. Check Match Status Before Deletion:
```sql
SELECT MatchID, MatchStatus, MatchDate
FROM Matches
WHERE MatchID = ?
```

### 2. Delete Match (Only if Not Completed):
```sql
DELETE FROM Matches 
WHERE MatchID = ? 
  AND MatchStatus != 'Completed'
```

### 3. Cancel Match Instead of Deleting:
```sql
UPDATE Matches 
SET MatchStatus = 'Cancelled' 
WHERE MatchID = ?
```

## Match Analytics Queries:
### 1. Team Performance Statistics:
```sql
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    COUNT(DISTINCT m.MatchID) as TotalMatches,
    SUM(CASE 
        WHEN m.MatchStatus = 'Completed' AND 
             ((m.Team1ID = t.TeamID AND m.Team1Score > m.Team2Score) OR 
              (m.Team2ID = t.TeamID AND m.Team2Score > m.Team1Score))
        THEN 1 ELSE 0 
    END) as Wins,
    SUM(CASE 
        WHEN m.MatchStatus = 'Completed' AND 
             ((m.Team1ID = t.TeamID AND m.Team1Score < m.Team2Score) OR 
              (m.Team2ID = t.TeamID AND m.Team2Score < m.Team1Score))
        THEN 1 ELSE 0 
    END) as Losses,
    SUM(CASE 
        WHEN m.MatchStatus = 'Completed' AND m.Team1Score = m.Team2Score
        THEN 1 ELSE 0 
    END) as Draws,
    ROUND(
        (SUM(CASE 
            WHEN m.MatchStatus = 'Completed' AND 
                 ((m.Team1ID = t.TeamID AND m.Team1Score > m.Team2Score) OR 
                  (m.Team2ID = t.TeamID AND m.Team2Score > m.Team1Score))
            THEN 1 ELSE 0 
        END) * 100.0) / NULLIF(COUNT(CASE WHEN m.MatchStatus = 'Completed' THEN 1 END), 0), 
        2
    ) as WinPercentage
FROM Teams t
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Matches m ON (t.TeamID = m.Team1ID OR t.TeamID = m.Team2ID)
WHERE t.TeamID = ?
GROUP BY t.TeamID, t.TeamName, s.SportName
```

### 2. Venue Match Statistics:
```sql
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    s.SportName,
    COUNT(m.MatchID) as TotalMatches,
    COUNT(CASE WHEN m.MatchStatus = 'Completed' THEN 1 END) as CompletedMatches,
    COUNT(CASE WHEN m.MatchStatus = 'Scheduled' THEN 1 END) as UpcomingMatches,
    MAX(m.MatchDate) as LastMatchDate
FROM Venues v
LEFT JOIN Sports s ON v.SportID = s.SportID
LEFT JOIN Matches m ON v.VenueID = m.VenueID
WHERE v.VenueID = ?
GROUP BY v.VenueID, v.VenueName, v.Location, s.SportName
```

### 3. Match Calendar (Monthly View):
```sql
SELECT 
    DATE(MatchDate) as MatchDay,
    COUNT(*) as MatchesScheduled,
    GROUP_CONCAT(
        CONCAT(Team1Name, ' vs ', Team2Name, ' at ', TIME_FORMAT(MatchTime, '%H:%i'))
        SEPARATOR '; '
    ) as MatchDetails
FROM match_details
WHERE YEAR(MatchDate) = ? 
  AND MONTH(MatchDate) = ?
  AND MatchStatus = 'Scheduled'
GROUP BY DATE(MatchDate)
ORDER BY MatchDay
```

### 4. Head-to-Head Record:
```sql
SELECT 
    COUNT(*) as TotalMatches,
    SUM(CASE 
        WHEN Team1Score > Team2Score THEN 1 
        ELSE 0 
    END) as Team1Wins,
    SUM(CASE 
        WHEN Team2Score > Team1Score THEN 1 
        ELSE 0 
    END) as Team2Wins,
    SUM(CASE 
        WHEN Team1Score = Team2Score AND MatchStatus = 'Completed' THEN 1 
        ELSE 0 
    END) as Draws,
    AVG(Team1Score) as Team1AvgScore,
    AVG(Team2Score) as Team2AvgScore
FROM Matches
WHERE (Team1ID = ? AND Team2ID = ?) 
   OR (Team1ID = ? AND Team2ID = ?)
  AND MatchStatus = 'Completed'
```

### 5. Sport-wise Match Distribution:
```sql
SELECT 
    s.SportName,
    COUNT(m.MatchID) as TotalMatches,
    COUNT(CASE WHEN m.MatchStatus = 'Completed' THEN 1 END) as CompletedMatches,
    COUNT(CASE WHEN m.MatchStatus = 'Scheduled' THEN 1 END) as UpcomingMatches,
    COUNT(CASE WHEN m.MatchStatus = 'Cancelled' THEN 1 END) as CancelledMatches
FROM Sports s
LEFT JOIN Teams t ON s.SportID = t.SportID
LEFT JOIN Matches m ON (t.TeamID = m.Team1ID OR t.TeamID = m.Team2ID)
GROUP BY s.SportName
ORDER BY TotalMatches DESC
```

## Match Leaderboard Queries:
### 1. Top Teams by Wins:
```sql
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    COUNT(CASE WHEN m.MatchStatus = 'Completed' THEN 1 END) as MatchesPlayed,
    SUM(CASE 
        WHEN m.MatchStatus = 'Completed' AND 
             ((m.Team1ID = t.TeamID AND m.Team1Score > m.Team2Score) OR 
              (m.Team2ID = t.TeamID AND m.Team2Score > m.Team1Score))
        THEN 1 ELSE 0 
    END) as Wins,
    ROUND(
        (SUM(CASE 
            WHEN m.MatchStatus = 'Completed' AND 
                 ((m.Team1ID = t.TeamID AND m.Team1Score > m.Team2Score) OR 
                  (m.Team2ID = t.TeamID AND m.Team2Score > m.Team1Score))
            THEN 1 ELSE 0 
        END) * 100.0) / NULLIF(COUNT(CASE WHEN m.MatchStatus = 'Completed' THEN 1 END), 0), 
        2
    ) as WinRate
FROM Teams t
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Matches m ON (t.TeamID = m.Team1ID OR t.TeamID = m.Team2ID)
GROUP BY t.TeamID, t.TeamName, s.SportName
HAVING MatchesPlayed >= 3
ORDER BY Wins DESC, WinRate DESC
LIMIT 10
```

### 2. Most Active Teams (By Matches Played):
```sql
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    u.Name as CaptainName,
    COUNT(DISTINCT m.MatchID) as TotalMatches,
    COUNT(DISTINCT CASE WHEN m.MatchStatus = 'Completed' THEN m.MatchID END) as CompletedMatches,
    COUNT(DISTINCT CASE WHEN m.MatchStatus = 'Scheduled' THEN m.MatchID END) as UpcomingMatches
FROM Teams t
LEFT JOIN Sports s ON t.SportID = s.SportID
LEFT JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN Matches m ON (t.TeamID = m.Team1ID OR t.TeamID = m.Team2ID)
GROUP BY t.TeamID, t.TeamName, s.SportName, u.Name
ORDER BY TotalMatches DESC
LIMIT 10
```

### 3. Recent Match Results:
```sql
SELECT 
    MatchID,
    MatchTitle,
    Team1Name,
    Team1Score,
    Team2Name,
    Team2Score,
    Winner,
    VenueName,
    MatchDate,
    MatchTime,
    SportName
FROM match_details
WHERE MatchStatus = 'Completed'
ORDER BY MatchDate DESC, MatchTime DESC
LIMIT 20
```



