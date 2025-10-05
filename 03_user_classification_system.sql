-- ================================================
-- TeamTango User Classification System Implementation
-- Purpose: Implement procedures, triggers, and permission system
-- Date: October 5, 2025
-- Usage: mysql -u root -p dbms_cp < 03_user_classification_system.sql
-- Prerequisite: Run 01_database_creation.sql and 02_sample_data_insertion.sql first
-- ================================================

USE dbms_cp;

-- ================================================
-- 1. USER PERMISSION TABLES
-- ================================================

-- Create table to define permissions for different user types
CREATE TABLE IF NOT EXISTS UserPermissions (
    PermissionID INT PRIMARY KEY AUTO_INCREMENT,
    RoleID INT,
    TableName VARCHAR(50),
    CanSelect BOOLEAN DEFAULT FALSE,
    CanInsert BOOLEAN DEFAULT FALSE,
    CanUpdate BOOLEAN DEFAULT FALSE,
    CanDelete BOOLEAN DEFAULT FALSE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE,
    UNIQUE KEY unique_role_table (RoleID, TableName)
);

-- Insert permission rules for Players and Venue Owners only
INSERT IGNORE INTO UserPermissions (RoleID, TableName, CanSelect, CanInsert, CanUpdate, CanDelete) VALUES
-- Player permissions (RoleID = 1) - INSERT & VIEW authority only
(1, 'Venues', TRUE, FALSE, FALSE, FALSE),           -- Can view venues
(1, 'Sports', TRUE, FALSE, FALSE, FALSE),           -- Can view sports
(1, 'Teams', TRUE, TRUE, TRUE, FALSE),              -- Can create and update own teams only
(1, 'TeamMembers', TRUE, TRUE, TRUE, FALSE),       -- Can join/leave teams
(1, 'Matches', TRUE, TRUE, TRUE, FALSE),           -- Can view and create matches for own teams
(1, 'Bookings', TRUE, TRUE, TRUE, FALSE),          -- Can make and update own bookings
(1, 'Payments', TRUE, TRUE, FALSE, FALSE),         -- Can view and make payments
(1, 'Feedback', TRUE, TRUE, TRUE, FALSE),          -- Can give and update own feedback
(1, 'Notifications', TRUE, FALSE, FALSE, FALSE),   -- Can view notifications only
(1, 'Timeslots', TRUE, FALSE, FALSE, FALSE),       -- Can view available timeslots
(1, 'Users', FALSE, FALSE, TRUE, FALSE),           -- Can update own profile only

-- Venue Owner permissions (RoleID = 2) - INSERT & VIEW authority + venue management
(2, 'Venues', TRUE, TRUE, TRUE, FALSE),            -- Can manage own venues only
(2, 'Sports', TRUE, FALSE, FALSE, FALSE),          -- Can view sports
(2, 'Teams', TRUE, FALSE, FALSE, FALSE),           -- Can view teams (for bookings)
(2, 'TeamMembers', TRUE, FALSE, FALSE, FALSE),     -- Can view team members
(2, 'Matches', TRUE, FALSE, FALSE, FALSE),         -- Can view matches at their venues
(2, 'Bookings', TRUE, FALSE, TRUE, FALSE),         -- Can update booking status for their venues
(2, 'Payments', TRUE, FALSE, TRUE, FALSE),         -- Can update payment status for their venues
(2, 'Feedback', TRUE, FALSE, FALSE, FALSE),        -- Can view feedback about their venues
(2, 'Notifications', TRUE, TRUE, FALSE, FALSE),    -- Can send notifications to players
(2, 'Timeslots', TRUE, TRUE, TRUE, FALSE),         -- Can manage timeslots for own venues
(2, 'Users', FALSE, FALSE, TRUE, FALSE);           -- Can update own profile only

-- ================================================
-- 2. USER ACTIVITY LOGGING TABLE
-- ================================================

CREATE TABLE IF NOT EXISTS UserActivityLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    Action VARCHAR(50),
    TableName VARCHAR(50),
    RecordID INT,
    ActionDetails TEXT,
    IPAddress VARCHAR(45),
    UserAgent TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL,
    INDEX idx_activity_user (UserID),
    INDEX idx_activity_table (TableName),
    INDEX idx_activity_action (Action),
    INDEX idx_activity_date (CreatedAt)
);

-- ================================================
-- 3. STORED PROCEDURES FOR USER CLASSIFICATION
-- ================================================

DELIMITER //

-- Procedure to check user permissions
CREATE PROCEDURE CheckUserPermission(
    IN p_UserID INT,
    IN p_TableName VARCHAR(50),
    IN p_Action VARCHAR(10)
)
BEGIN
    DECLARE v_RoleID INT;
    DECLARE v_HasPermission BOOLEAN DEFAULT FALSE;
    
    -- Get user's role
    SELECT RoleID INTO v_RoleID FROM Users WHERE UserID = p_UserID;
    
    -- Check permission based on action
    CASE p_Action
        WHEN 'SELECT' THEN
            SELECT CanSelect INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName;
        WHEN 'INSERT' THEN
            SELECT CanInsert INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName;
        WHEN 'UPDATE' THEN
            SELECT CanUpdate INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName;
        WHEN 'DELETE' THEN
            SELECT CanDelete INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName;
    END CASE;
    
    -- Return result
    SELECT v_HasPermission as HasPermission, v_RoleID as UserRole;
END //

-- Procedure to get user classification
CREATE PROCEDURE GetUserClassification(IN p_UserID INT)
BEGIN
    SELECT 
        u.UserID,
        u.Name,
        u.Email,
        r.RoleName,
        CASE 
            WHEN r.RoleID = 1 THEN 'Player'
            WHEN r.RoleID = 2 THEN 'Venue Owner'
            ELSE 'Unknown'
        END as UserType,
        CASE 
            WHEN r.RoleID = 1 THEN 'Can create teams, make bookings, join matches, give feedback'
            WHEN r.RoleID = 2 THEN 'Can manage own venues, timeslots, view bookings for their venues'
            ELSE 'Limited access'
        END as AccessDescription
    FROM Users u
    LEFT JOIN Roles r ON u.RoleID = r.RoleID
    WHERE u.UserID = p_UserID;
END //

-- Procedure to create new user with automatic role assignment
CREATE PROCEDURE CreateUserWithRole(
    IN p_Name VARCHAR(100),
    IN p_Email VARCHAR(100),
    IN p_Gender ENUM('Male', 'Female', 'Other'),
    IN p_Password VARCHAR(255),
    IN p_PhoneNumber VARCHAR(15),
    IN p_Address TEXT,
    IN p_UserType VARCHAR(20) -- 'player' or 'venue_owner'
)
BEGIN
    DECLARE v_RoleID INT DEFAULT 1;
    DECLARE v_UserID INT;
    
    -- Determine RoleID based on user type
    CASE p_UserType
        WHEN 'player' THEN SET v_RoleID = 1;
        WHEN 'venue_owner' THEN SET v_RoleID = 2;
        ELSE SET v_RoleID = 1; -- Default to player
    END CASE;
    
    -- Insert new user
    INSERT INTO Users (Name, Email, Gender, Password, PhoneNumber, Address, RoleID)
    VALUES (p_Name, p_Email, p_Gender, p_Password, p_PhoneNumber, p_Address, v_RoleID);
    
    SET v_UserID = LAST_INSERT_ID();
    
    -- Log the user creation
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (v_UserID, 'CREATE', 'Users', v_UserID, CONCAT('New user created with role: ', p_UserType));
    
    -- Return user details
    SELECT v_UserID as UserID, v_RoleID as RoleID, 'User created successfully' as Message;
END //

-- Procedure to check if user owns a specific resource (for permission validation)
CREATE PROCEDURE CheckResourceOwnership(
    IN p_UserID INT,
    IN p_TableName VARCHAR(50),
    IN p_ResourceID INT
)
BEGIN
    DECLARE v_IsOwner BOOLEAN DEFAULT FALSE;
    DECLARE v_RoleID INT;
    
    -- Get user's role
    SELECT RoleID INTO v_RoleID FROM Users WHERE UserID = p_UserID;
    
    -- Check ownership based on table and role
    CASE 
        WHEN p_TableName = 'Teams' AND v_RoleID = 1 THEN
            SELECT COUNT(*) > 0 INTO v_IsOwner 
            FROM Teams WHERE TeamID = p_ResourceID AND CaptainID = p_UserID;
        
        WHEN p_TableName = 'Venues' AND v_RoleID = 2 THEN
            SELECT COUNT(*) > 0 INTO v_IsOwner 
            FROM Venues WHERE VenueID = p_ResourceID AND OwnerID = p_UserID;
            
        WHEN p_TableName = 'Bookings' THEN
            -- Players can modify their own bookings, venue owners can modify bookings for their venues
            IF v_RoleID = 1 THEN
                SELECT COUNT(*) > 0 INTO v_IsOwner 
                FROM Bookings WHERE BookingID = p_ResourceID AND UserID = p_UserID;
            ELSEIF v_RoleID = 2 THEN
                SELECT COUNT(*) > 0 INTO v_IsOwner 
                FROM Bookings b 
                JOIN Venues v ON b.VenueID = v.VenueID 
                WHERE b.BookingID = p_ResourceID AND v.OwnerID = p_UserID;
            END IF;
            
        WHEN p_TableName = 'Feedback' AND v_RoleID = 1 THEN
            SELECT COUNT(*) > 0 INTO v_IsOwner 
            FROM Feedback WHERE FeedbackID = p_ResourceID AND UserID = p_UserID;
    END CASE;
    
    SELECT v_IsOwner as IsOwner, v_RoleID as UserRole;
END //

DELIMITER ;

-- ================================================
-- 4. TRIGGERS FOR USER ACTIVITY MONITORING
-- ================================================

DELIMITER //

-- Trigger for Users table updates
CREATE TRIGGER tr_users_update_log
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.UserID, 'UPDATE', 'Users', NEW.UserID, 
            CONCAT('Profile updated - Name: ', NEW.Name, ', Email: ', NEW.Email));
END //

-- Trigger for new bookings
CREATE TRIGGER tr_bookings_insert_log
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.UserID, 'INSERT', 'Bookings', NEW.BookingID, 
            CONCAT('New booking created for venue ID: ', NEW.VenueID));
END //

-- Trigger for new team creation
CREATE TRIGGER tr_teams_insert_log
AFTER INSERT ON Teams
FOR EACH ROW
BEGIN
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.CaptainID, 'INSERT', 'Teams', NEW.TeamID, 
            CONCAT('New team created: ', NEW.TeamName));
END //

-- Trigger for match creation
CREATE TRIGGER tr_matches_insert_log
AFTER INSERT ON Matches
FOR EACH ROW
BEGIN
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.CreatedByUserID, 'INSERT', 'Matches', NEW.MatchID, 
            CONCAT('New match scheduled between Team ', NEW.Team1ID, ' and Team ', NEW.Team2ID));
END //

-- Trigger to prevent unauthorized venue modifications
CREATE TRIGGER tr_venue_ownership_check
BEFORE UPDATE ON Venues
FOR EACH ROW
BEGIN
    -- This trigger helps ensure venue owners can only modify their own venues
    -- The application layer should validate this, but this is a safety measure
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.OwnerID, 'UPDATE', 'Venues', NEW.VenueID, 
            CONCAT('Venue updated: ', NEW.VenueName));
END //

-- Trigger for team ownership validation
CREATE TRIGGER tr_team_captain_log
AFTER UPDATE ON Teams
FOR EACH ROW
BEGIN
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.CaptainID, 'UPDATE', 'Teams', NEW.TeamID, 
            CONCAT('Team updated: ', NEW.TeamName, ' by captain ID: ', NEW.CaptainID));
END //

-- Trigger to log payment transactions
CREATE TRIGGER tr_payment_log
AFTER INSERT ON Payments
FOR EACH ROW
BEGIN
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.UserID, 'INSERT', 'Payments', NEW.PaymentID, 
            CONCAT('Payment made: ₹', NEW.Amount, ' for booking ID: ', NEW.BookingID));
END //

-- Trigger to validate team membership
CREATE TRIGGER tr_team_member_log
AFTER INSERT ON TeamMembers
FOR EACH ROW
BEGIN
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (NEW.UserID, 'INSERT', 'TeamMembers', NEW.MemberID, 
            CONCAT('User joined team ID: ', NEW.TeamID));
END //

DELIMITER ;

-- ================================================
-- 5. VIEWS FOR USER CLASSIFICATION
-- ================================================

-- View for all users with their roles and permissions
CREATE OR REPLACE VIEW UserRoleView AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    r.RoleName,
    u.CreatedAt,
    CASE 
        WHEN r.RoleID = 1 THEN 'Player - Can create teams, make bookings, join matches'
        WHEN r.RoleID = 2 THEN 'Venue Owner - Can manage venues and timeslots'
        ELSE 'Unknown Role'
    END as UserDescription
FROM Users u
JOIN Roles r ON u.RoleID = r.RoleID
WHERE r.RoleID IN (1, 2);

-- View for players only
CREATE OR REPLACE VIEW PlayersView AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.Gender,
    u.Address,
    u.CreatedAt
FROM Users u
WHERE u.RoleID = 1;

-- View for venue owners only
CREATE OR REPLACE VIEW VenueOwnersView AS
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    u.PhoneNumber,
    u.Gender,
    u.Address,
    u.CreatedAt
FROM Users u
WHERE u.RoleID = 2;

-- View for user activity summary
CREATE OR REPLACE VIEW UserActivitySummary AS
SELECT 
    u.UserID,
    u.Name,
    r.RoleName,
    COUNT(ual.LogID) as TotalActivities,
    MAX(ual.CreatedAt) as LastActivity,
    GROUP_CONCAT(DISTINCT ual.Action) as Actions
FROM Users u
LEFT JOIN Roles r ON u.RoleID = r.RoleID
LEFT JOIN UserActivityLog ual ON u.UserID = ual.UserID
GROUP BY u.UserID, u.Name, r.RoleName;

-- ================================================
-- 6. FUNCTIONS FOR PERMISSION CHECKING
-- ================================================

DELIMITER //

-- Function to check if user can perform action
CREATE FUNCTION CanUserPerformAction(
    p_UserID INT,
    p_TableName VARCHAR(50),
    p_Action VARCHAR(10)
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_RoleID INT;
    DECLARE v_HasPermission BOOLEAN DEFAULT FALSE;
    
    -- Get user's role
    SELECT RoleID INTO v_RoleID FROM Users WHERE UserID = p_UserID;
    
    -- Check permission
    CASE p_Action
        WHEN 'SELECT' THEN
            SELECT CanSelect INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName LIMIT 1;
        WHEN 'INSERT' THEN
            SELECT CanInsert INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName LIMIT 1;
        WHEN 'UPDATE' THEN
            SELECT CanUpdate INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName LIMIT 1;
        WHEN 'DELETE' THEN
            SELECT CanDelete INTO v_HasPermission 
            FROM UserPermissions 
            WHERE RoleID = v_RoleID AND TableName = p_TableName LIMIT 1;
    END CASE;
    
    RETURN IFNULL(v_HasPermission, FALSE);
END //

-- Function to get user type description
CREATE FUNCTION GetUserTypeDescription(p_UserID INT) 
RETURNS VARCHAR(100)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_RoleID INT;
    DECLARE v_Description VARCHAR(100);
    
    SELECT RoleID INTO v_RoleID FROM Users WHERE UserID = p_UserID;
    
    CASE v_RoleID
        WHEN 1 THEN SET v_Description = 'Player - Can create teams, make bookings, join matches';
        WHEN 2 THEN SET v_Description = 'Venue Owner - Can manage venues and timeslots';
        ELSE SET v_Description = 'Unknown User Type';
    END CASE;
    
    RETURN v_Description;
END //

DELIMITER ;

-- ================================================
-- SUCCESS MESSAGE AND VERIFICATION
-- ================================================

-- Show user count by role
SELECT 'User Classification System Implemented Successfully!' as Status;

SELECT 
    r.RoleName,
    COUNT(u.UserID) as UserCount
FROM Roles r
LEFT JOIN Users u ON r.RoleID = u.RoleID
WHERE r.RoleID IN (1, 2)
GROUP BY r.RoleID, r.RoleName;

-- Show user permissions summary
SELECT 
    r.RoleName,
    COUNT(up.PermissionID) as PermissionCount,
    SUM(up.CanSelect) as SelectPermissions,
    SUM(up.CanInsert) as InsertPermissions,
    SUM(up.CanUpdate) as UpdatePermissions,
    SUM(up.CanDelete) as DeletePermissions
FROM Roles r
LEFT JOIN UserPermissions up ON r.RoleID = up.RoleID
WHERE r.RoleID IN (1, 2)
GROUP BY r.RoleID, r.RoleName;

-- Test the system with sample procedure calls
SELECT 'Testing User Classification:' as TestSection;
CALL GetUserClassification(1);
CALL CheckUserPermission(1, 'Teams', 'INSERT');

SELECT 'System Ready!' as FinalStatus,
       'Players: Can create teams, make bookings, join matches (INSERT & VIEW)' as PlayerRights,
       'Venue Owners: Can manage own venues and timeslots (INSERT & VIEW + venue management)' as VenueOwnerRights;