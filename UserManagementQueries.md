## User Registration Queries:
### 1. Check Email Availability:
```sql
SELECT UserID 
FROM Users 
WHERE Email = ?
```

### 2. Hash Password (Done in Application Layer):
```javascript
// Using bcrypt in Node.js
const saltRounds = 10;
const hashedPassword = await bcrypt.hash(password, saltRounds);
```

### 3. Create New User Account:
```sql
INSERT INTO Users (Name, Email, Gender, Password, PhoneNumber, Address, RoleID)
VALUES (?, ?, ?, ?, ?, ?, ?)
```

### 4. User Registration Using Stored Procedure:
```sql
DELIMITER //

CREATE PROCEDURE RegisterUser(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_phone VARCHAR(15),
    IN p_address VARCHAR(255),
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_role_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM Users WHERE Email = p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email already registered';
    END IF;
    
    -- Insert new user
    INSERT INTO Users (Name, Email, Password, PhoneNumber, Address, Gender, RoleID)
    VALUES (p_name, p_email, p_password, p_phone, p_address, p_gender, p_role_id);
    
    COMMIT;
    
    SELECT 'User registered successfully!' as Message, LAST_INSERT_ID() as UserID;
END //

DELIMITER ;

-- Call the procedure
CALL RegisterUser(?, ?, ?, ?, ?, ?, ?)
```

### 5. Welcome Notification Trigger:
```sql
DELIMITER //

CREATE TRIGGER tr_user_welcome_notification
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    DECLARE welcome_message TEXT;
    
    SET welcome_message = CASE NEW.RoleID
        WHEN 1 THEN 'Welcome to TeamTango! Start exploring venues and join teams.'
        WHEN 2 THEN 'Welcome to TeamTango! You can now list your venues and manage bookings.'
        WHEN 3 THEN 'Admin access granted. Welcome to TeamTango administration.'
        ELSE 'Welcome to TeamTango!'
    END;
    
    INSERT INTO Notifications (UserID, Message, IsRead)
    VALUES (NEW.UserID, welcome_message, FALSE);
END //

DELIMITER ;
```

### 6. Audit Log for User Creation:
```sql
DELIMITER //

CREATE TRIGGER tr_user_insert_audit
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.UserID, 'INSERT', 'Users', NOW());
END //

DELIMITER ;
```

## User Login Queries:
### 1. Retrieve User by Email:
```sql
SELECT 
    u.UserID, 
    u.Name, 
    u.Email, 
    u.Password, 
    u.PhoneNumber, 
    u.RoleID, 
    r.RoleName 
FROM Users u 
LEFT JOIN Roles r ON u.RoleID = r.RoleID 
WHERE u.Email = ?
```

### 2. Password Verification (Application Layer):
```javascript
// Using bcrypt to compare passwords
const isPasswordValid = await bcrypt.compare(providedPassword, storedHashedPassword);
```

### 3. Login Using Stored Procedure:
```sql
DELIMITER //

CREATE PROCEDURE LoginUser(
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_role_id INT;
    DECLARE v_name VARCHAR(100);
    
    -- Find user with email and password
    SELECT UserID, Name, RoleID 
    INTO v_user_id, v_name, v_role_id
    FROM Users 
    WHERE Email = p_email AND Password = p_password;
    
    IF v_user_id IS NULL THEN
        SELECT 'Invalid credentials' as Status, NULL as UserID, NULL as Name, NULL as Role;
    ELSE
        SELECT 'Login successful' as Status, v_user_id as UserID, v_name as Name, v_role_id as RoleID;
    END IF;
END //

DELIMITER ;

-- Call the procedure
CALL LoginUser(?, ?)
```

### 4. Log User Login Activity:
```sql
INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
VALUES (?, 'LOGIN', 'Users', ?, 'User logged in successfully')
```

## Reading User Data Queries:
### 1. All Users with Role Information (Admin View):
```sql
SELECT 
    u.UserID, 
    u.Name, 
    u.Email, 
    u.Gender, 
    u.PhoneNumber, 
    u.Address, 
    u.CreatedAt,
    r.RoleName,
    u.RoleID
FROM Users u 
LEFT JOIN Roles r ON u.RoleID = r.RoleID 
ORDER BY u.CreatedAt DESC
```

### 2. Single User Profile with Statistics (Using View):
```sql
-- Using user_profiles view
SELECT 
    UserID,
    Name,
    Email,
    PhoneNumber,
    Gender,
    Address,
    CreatedAt,
    RoleID,
    RoleName,
    TotalBookings,
    TotalTeams,
    TotalSpent
FROM user_profiles
WHERE UserID = ?
```

### 3. Search Players (For Team Building):
```sql
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.Gender,
    u.PhoneNumber,
    u.Address,
    u.CreatedAt,
    r.RoleName,
    u.RoleID
FROM Users u
LEFT JOIN Roles r ON u.RoleID = r.RoleID
WHERE u.RoleID = 1  -- Only players
  AND (
    CAST(u.UserID AS CHAR) LIKE ? 
    OR u.Name LIKE ? 
    OR u.Email LIKE ? 
    OR u.Gender LIKE ? 
    OR u.PhoneNumber LIKE ?
  )
ORDER BY u.CreatedAt DESC
LIMIT 100
```

### 4. Get User's Complete Profile:
```sql
SELECT 
    u.*,
    r.RoleName,
    (SELECT COUNT(*) FROM Bookings b WHERE b.UserID = u.UserID) as TotalBookings,
    (SELECT COUNT(*) FROM TeamMembers tm WHERE tm.UserID = u.UserID) as TotalTeams,
    (SELECT COUNT(*) FROM Teams t WHERE t.CaptainID = u.UserID) as TeamsAsCaptain,
    (SELECT COALESCE(SUM(p.Amount), 0) 
     FROM Payments p 
     JOIN Bookings b ON p.BookingID = b.BookingID 
     WHERE b.UserID = u.UserID AND p.PaymentStatus = 'Success') as TotalSpent
FROM Users u
LEFT JOIN Roles r ON u.RoleID = r.RoleID
WHERE u.UserID = ?
```

### 5. Get Venue Owners List:
```sql
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.Address,
    COUNT(v.VenueID) as TotalVenues,
    COALESCE(SUM(
        (SELECT COUNT(*) FROM Bookings b WHERE b.VenueID = v.VenueID)
    ), 0) as TotalBookings
FROM Users u
LEFT JOIN Venues v ON u.UserID = v.OwnerID
WHERE u.RoleID = 2
GROUP BY u.UserID, u.Name, u.Email, u.PhoneNumber, u.Address
ORDER BY TotalVenues DESC
```

## User Update Queries:
### 1. Check User Exists Before Update:
```sql
SELECT UserID, Name, Email 
FROM Users 
WHERE UserID = ?
```

### 2. Update User Profile Information:
```sql
UPDATE Users 
SET Name = ?, 
    PhoneNumber = ?, 
    Address = ?, 
    Gender = ? 
WHERE UserID = ?
```

### 3. Update Password (With Hashing):
```sql
-- First verify old password in application
-- Then update with new hashed password
UPDATE Users 
SET Password = ? 
WHERE UserID = ? AND Password = ?
```

### 4. Update User Profile Using Stored Procedure:
```sql
DELIMITER //

CREATE PROCEDURE UpdateUserProfile(
    IN p_user_id INT,
    IN p_name VARCHAR(100),
    IN p_phone VARCHAR(15),
    IN p_address VARCHAR(255),
    IN p_gender ENUM('Male', 'Female', 'Other')
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    END IF;
    
    -- Update user information
    UPDATE Users 
    SET Name = p_name, 
        PhoneNumber = p_phone, 
        Address = p_address, 
        Gender = p_gender
    WHERE UserID = p_user_id;
    
    COMMIT;
    
    SELECT 'Profile updated successfully!' as Message;
END //

DELIMITER ;

-- Call the procedure
CALL UpdateUserProfile(?, ?, ?, ?, ?)
```

### 5. Update User Role (Admin Only):
```sql
UPDATE Users 
SET RoleID = ? 
WHERE UserID = ?
```

### 6. Audit Trigger for User Updates:
```sql
DELIMITER //

CREATE TRIGGER tr_user_update_audit
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (UserID, Action, TableName, Timestamp)
    VALUES (NEW.UserID, 'UPDATE', 'Users', NOW());
END //

DELIMITER ;
```

## User Deletion Queries:
### 1. Check User Dependencies Before Deletion:
```sql
-- Check for active bookings
SELECT COUNT(*) as ActiveBookings
FROM Bookings
WHERE UserID = ? 
  AND BookingStatus IN ('Pending', 'Confirmed')

-- Check if user is team captain
SELECT COUNT(*) as TeamsAsCaptain
FROM Teams
WHERE CaptainID = ?

-- Check for owned venues
SELECT COUNT(*) as OwnedVenues
FROM Venues
WHERE OwnerID = ?
```

### 2. Soft Delete User (Deactivate):
```sql
-- Add IsActive column to Users table first
ALTER TABLE Users ADD COLUMN IsActive BOOLEAN DEFAULT TRUE;

-- Soft delete
UPDATE Users 
SET IsActive = FALSE 
WHERE UserID = ?
```

### 3. Hard Delete User (Cascade Considerations):
```sql
-- This will fail if user has foreign key dependencies
-- Need to handle cascading deletes or restrict deletion
DELETE FROM Users 
WHERE UserID = ?
```

### 4. Safe User Deletion Procedure:
```sql
DELIMITER //

CREATE PROCEDURE SafeDeleteUser(
    IN p_user_id INT
)
BEGIN
    DECLARE v_active_bookings INT;
    DECLARE v_teams_as_captain INT;
    DECLARE v_owned_venues INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check dependencies
    SELECT COUNT(*) INTO v_active_bookings
    FROM Bookings
    WHERE UserID = p_user_id 
      AND BookingStatus IN ('Pending', 'Confirmed');
    
    SELECT COUNT(*) INTO v_teams_as_captain
    FROM Teams
    WHERE CaptainID = p_user_id;
    
    SELECT COUNT(*) INTO v_owned_venues
    FROM Venues
    WHERE OwnerID = p_user_id;
    
    -- Prevent deletion if dependencies exist
    IF v_active_bookings > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete user with active bookings';
    END IF;
    
    IF v_teams_as_captain > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete user who is team captain';
    END IF;
    
    IF v_owned_venues > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete user with owned venues';
    END IF;
    
    -- Safe to delete - remove team memberships first
    DELETE FROM TeamMembers WHERE UserID = p_user_id;
    
    -- Delete the user
    DELETE FROM Users WHERE UserID = p_user_id;
    
    COMMIT;
    
    SELECT 'User deleted successfully!' as Message;
END //

DELIMITER ;

-- Call the procedure
CALL SafeDeleteUser(?)
```

## User Analytics Queries:
### 1. User Activity Report:
```sql
SELECT 
    'Teams' as Category,
    COUNT(tm.TeamID) as Count,
    GROUP_CONCAT(t.TeamName SEPARATOR ', ') as Details
FROM TeamMembers tm
INNER JOIN Teams t ON tm.TeamID = t.TeamID
WHERE tm.UserID = ?

UNION ALL

SELECT 
    'Bookings' as Category,
    COUNT(b.BookingID) as Count,
    CONCAT('Total Spent: ₹', COALESCE(SUM(b.TotalAmount), 0)) as Details
FROM Bookings b
WHERE b.UserID = ?

UNION ALL

SELECT 
    'Matches' as Category,
    COUNT(DISTINCT m.MatchID) as Count,
    'Upcoming and completed matches' as Details
FROM Matches m
INNER JOIN Teams t ON (m.Team1ID = t.TeamID OR m.Team2ID = t.TeamID)
INNER JOIN TeamMembers tm ON t.TeamID = tm.TeamID
WHERE tm.UserID = ?
```

### 2. User Registration Statistics:
```sql
SELECT 
    DATE(CreatedAt) as RegistrationDate,
    COUNT(*) as NewUsers,
    SUM(CASE WHEN RoleID = 1 THEN 1 ELSE 0 END) as NewPlayers,
    SUM(CASE WHEN RoleID = 2 THEN 1 ELSE 0 END) as NewVenueOwners
FROM Users
WHERE CreatedAt >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(CreatedAt)
ORDER BY RegistrationDate DESC
```

### 3. Most Active Users:
```sql
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    r.RoleName,
    COUNT(DISTINCT b.BookingID) as TotalBookings,
    COUNT(DISTINCT tm.TeamID) as TeamsJoined,
    COALESCE(SUM(CASE WHEN p.PaymentStatus = 'Success' THEN p.Amount ELSE 0 END), 0) as TotalSpent
FROM Users u
LEFT JOIN Roles r ON u.RoleID = r.RoleID
LEFT JOIN Bookings b ON u.UserID = b.UserID
LEFT JOIN TeamMembers tm ON u.UserID = tm.UserID
LEFT JOIN Payments p ON b.BookingID = p.BookingID
WHERE u.RoleID = 1  -- Only players
GROUP BY u.UserID, u.Name, u.Email, r.RoleName
ORDER BY TotalBookings DESC
LIMIT 20
```

### 4. User Growth Over Time:
```sql
SELECT 
    YEAR(CreatedAt) as Year,
    MONTH(CreatedAt) as Month,
    MONTHNAME(CreatedAt) as MonthName,
    COUNT(*) as NewUsers,
    SUM(COUNT(*)) OVER (ORDER BY YEAR(CreatedAt), MONTH(CreatedAt)) as CumulativeUsers
FROM Users
GROUP BY YEAR(CreatedAt), MONTH(CreatedAt), MONTHNAME(CreatedAt)
ORDER BY Year DESC, Month DESC
```

### 5. Role Distribution:
```sql
SELECT 
    r.RoleName,
    r.Description,
    COUNT(u.UserID) as UserCount,
    ROUND(COUNT(u.UserID) * 100.0 / (SELECT COUNT(*) FROM Users), 2) as Percentage
FROM Roles r
LEFT JOIN Users u ON r.RoleID = u.RoleID
GROUP BY r.RoleName, r.Description
ORDER BY UserCount DESC
```

## User Validation Queries:
### 1. Validate Email Format:
```sql
SELECT Email 
FROM Users 
WHERE Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
  AND UserID = ?
```

### 2. Validate Phone Number Format (Trigger):
```sql
-- Already defined in schema
CONSTRAINT chk_users_phone_format CHECK (PhoneNumber REGEXP '^[0-9]{10}$')
```

### 3. Validate Name Length:
```sql
-- Already defined in schema
CONSTRAINT chk_users_name_length CHECK (CHAR_LENGTH(Name) >= 2)
```

### 4. Check Unique Email Before Insert:
```sql
SELECT COUNT(*) as EmailExists
FROM Users
WHERE Email = ? AND UserID != ?
```

## User Session Management Queries:
### 1. Get Current User Session Info:
```sql
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.RoleID,
    r.RoleName,
    COUNT(DISTINCT n.NotificationID) as UnreadNotifications
FROM Users u
LEFT JOIN Roles r ON u.RoleID = r.RoleID
LEFT JOIN Notifications n ON u.UserID = n.UserID AND n.IsRead = FALSE
WHERE u.UserID = ?
GROUP BY u.UserID, u.Name, u.Email, u.RoleID, r.RoleName
```

### 2. Get User Permissions:
```sql
SELECT 
    up.TableName,
    up.CanCreate,
    up.CanRead,
    up.CanUpdate,
    up.CanDelete
FROM UserPermissions up
WHERE up.RoleID = ?
ORDER BY up.TableName
```

### 3. Verify User Access to Resource:
```sql
SELECT 
    up.CanRead,
    up.CanUpdate,
    up.CanDelete
FROM UserPermissions up
WHERE up.RoleID = ?
  AND up.TableName = ?
```
