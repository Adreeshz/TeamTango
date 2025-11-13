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



