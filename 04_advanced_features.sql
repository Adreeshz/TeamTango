-- ================================================
-- TeamTango Advanced Database Features (Additional Triggers & Procedures)
-- Purpose: Advanced business logic, validation, and analytics
-- Date: October 5, 2025
-- Usage: mysql -u root -p dbms_cp < 04_advanced_features.sql
-- Prerequisite: Run 00_complete_setup.sql first
-- Note: This file contains additional features for production use
-- ================================================

USE dbms_cp;

-- ================================================
-- 1. DATA VALIDATION TRIGGERS
-- ================================================

DELIMITER //

-- Trigger to validate venue capacity
CREATE TRIGGER tr_venues_capacity_validation
BEFORE INSERT ON Venues
FOR EACH ROW
BEGIN
    IF NEW.Capacity <= 0 OR NEW.Capacity > 1000 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Venue capacity must be between 1 and 1000';
    END IF;
    
    IF NEW.PricePerHour < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Venue price cannot be negative';
    END IF;
END //

-- Trigger to validate booking dates
CREATE TRIGGER tr_bookings_date_validation
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.BookingDate < CURDATE() THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot book venues for past dates';
    END IF;
    
    IF NEW.StartTime >= NEW.EndTime THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Booking start time must be before end time';
    END IF;
    
    IF NEW.TotalAmount < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Booking amount cannot be negative';
    END IF;
END //

-- Trigger to validate team size limits
CREATE TRIGGER tr_team_members_limit_check
BEFORE INSERT ON TeamMembers
FOR EACH ROW
BEGIN
    DECLARE v_CurrentMembers INT;
    DECLARE v_MaxMembers INT;
    
    SELECT COUNT(*) INTO v_CurrentMembers 
    FROM TeamMembers 
    WHERE TeamID = NEW.TeamID AND IsActive = TRUE;
    
    SELECT MaxMembers INTO v_MaxMembers 
    FROM Teams 
    WHERE TeamID = NEW.TeamID;
    
    IF v_CurrentMembers >= v_MaxMembers THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Team has reached maximum member limit';
    END IF;
END //

-- Trigger to validate feedback ratings
CREATE TRIGGER tr_feedback_rating_validation
BEFORE INSERT ON Feedback
FOR EACH ROW
BEGIN
    IF NEW.Rating < 1 OR NEW.Rating > 5 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;
END //

-- Trigger to prevent double booking of timeslots
CREATE TRIGGER tr_timeslots_overlap_prevention
BEFORE INSERT ON Timeslots
FOR EACH ROW
BEGIN
    DECLARE v_OverlapCount INT;
    
    SELECT COUNT(*) INTO v_OverlapCount
    FROM Timeslots 
    WHERE VenueID = NEW.VenueID 
    AND SlotDate = NEW.SlotDate
    AND (
        (NEW.StartTime >= StartTime AND NEW.StartTime < EndTime) OR
        (NEW.EndTime > StartTime AND NEW.EndTime <= EndTime) OR
        (NEW.StartTime <= StartTime AND NEW.EndTime >= EndTime)
    );
    
    IF v_OverlapCount > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Timeslot overlaps with existing slot';
    END IF;
END //

DELIMITER ;

-- ================================================
-- 2. BUSINESS LOGIC PROCEDURES
-- ================================================

DELIMITER //

-- Procedure to create a complete booking with validation
CREATE PROCEDURE CreateBookingWithValidation(
    IN p_UserID INT,
    IN p_VenueID INT,
    IN p_BookingDate DATE,
    IN p_StartTime TIME,
    IN p_EndTime TIME,
    IN p_PaymentMethod VARCHAR(20)
)
BEGIN
    DECLARE v_TimeslotID INT DEFAULT NULL;
    DECLARE v_PricePerHour DECIMAL(10,2);
    DECLARE v_TotalHours DECIMAL(4,2);
    DECLARE v_TotalAmount DECIMAL(10,2);
    DECLARE v_BookingID INT;
    DECLARE v_PaymentID INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check if venue exists and is active
    SELECT PricePerHour INTO v_PricePerHour 
    FROM Venues 
    WHERE VenueID = p_VenueID AND IsActive = TRUE;
    
    IF v_PricePerHour IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Venue not found or inactive';
    END IF;
    
    -- Find matching timeslot
    SELECT TimeslotID INTO v_TimeslotID
    FROM Timeslots 
    WHERE VenueID = p_VenueID 
    AND SlotDate = p_BookingDate 
    AND StartTime = p_StartTime 
    AND EndTime = p_EndTime 
    AND IsAvailable = TRUE
    LIMIT 1;
    
    -- Calculate total amount
    SET v_TotalHours = TIMESTAMPDIFF(MINUTE, p_StartTime, p_EndTime) / 60.0;
    SET v_TotalAmount = v_PricePerHour * v_TotalHours;
    
    -- Create booking
    INSERT INTO Bookings (UserID, VenueID, TimeslotID, BookingDate, StartTime, EndTime, TotalAmount, Status)
    VALUES (p_UserID, p_VenueID, v_TimeslotID, p_BookingDate, p_StartTime, p_EndTime, v_TotalAmount, 'Confirmed');
    
    SET v_BookingID = LAST_INSERT_ID();
    
    -- Mark timeslot as unavailable if exists
    IF v_TimeslotID IS NOT NULL THEN
        UPDATE Timeslots SET IsAvailable = FALSE WHERE TimeslotID = v_TimeslotID;
    END IF;
    
    -- Create payment record
    INSERT INTO Payments (BookingID, UserID, Amount, PaymentMethod, PaymentStatus)
    VALUES (v_BookingID, p_UserID, v_TotalAmount, p_PaymentMethod, 'Success');
    
    SET v_PaymentID = LAST_INSERT_ID();
    
    -- Log the transaction
    INSERT INTO UserActivityLog (UserID, Action, TableName, RecordID, ActionDetails)
    VALUES (p_UserID, 'CREATE', 'Bookings', v_BookingID, 
            CONCAT('Complete booking created for ₹', v_TotalAmount));
    
    COMMIT;
    
    -- Return booking details
    SELECT v_BookingID as BookingID, v_PaymentID as PaymentID, v_TotalAmount as Amount, 'Booking created successfully' as Message;
END //

-- Procedure to get venue availability for a specific date
CREATE PROCEDURE GetVenueAvailability(
    IN p_VenueID INT,
    IN p_Date DATE
)
BEGIN
    SELECT 
        ts.TimeslotID,
        ts.StartTime,
        ts.EndTime,
        ts.PriceINR,
        ts.IsAvailable,
        CASE 
            WHEN b.BookingID IS NOT NULL THEN 'Booked'
            WHEN ts.IsAvailable = FALSE THEN 'Unavailable'
            ELSE 'Available'
        END as Status
    FROM Timeslots ts
    LEFT JOIN Bookings b ON ts.TimeslotID = b.TimeslotID 
                        AND b.Status IN ('Confirmed', 'Pending')
    WHERE ts.VenueID = p_VenueID 
    AND ts.SlotDate = p_Date
    ORDER BY ts.StartTime;
END //

-- Procedure to get team performance statistics
CREATE PROCEDURE GetTeamPerformanceStats(IN p_TeamID INT)
BEGIN
    DECLARE v_TotalMatches INT DEFAULT 0;
    DECLARE v_Wins INT DEFAULT 0;
    DECLARE v_Losses INT DEFAULT 0;
    DECLARE v_Draws INT DEFAULT 0;
    
    -- Count total matches
    SELECT COUNT(*) INTO v_TotalMatches
    FROM Matches 
    WHERE (Team1ID = p_TeamID OR Team2ID = p_TeamID) 
    AND Status = 'Completed';
    
    -- Count wins
    SELECT COUNT(*) INTO v_Wins
    FROM Matches 
    WHERE WinnerTeamID = p_TeamID 
    AND Status = 'Completed';
    
    -- Count losses  
    SELECT COUNT(*) INTO v_Losses
    FROM Matches 
    WHERE (Team1ID = p_TeamID OR Team2ID = p_TeamID) 
    AND WinnerTeamID IS NOT NULL 
    AND WinnerTeamID != p_TeamID 
    AND Status = 'Completed';
    
    -- Draws = Total - Wins - Losses
    SET v_Draws = v_TotalMatches - v_Wins - v_Losses;
    
    -- Return statistics
    SELECT 
        p_TeamID as TeamID,
        t.TeamName,
        v_TotalMatches as TotalMatches,
        v_Wins as Wins,
        v_Losses as Losses,
        v_Draws as Draws,
        CASE 
            WHEN v_TotalMatches = 0 THEN 0.00
            ELSE ROUND((v_Wins * 100.0 / v_TotalMatches), 2)
        END as WinPercentage
    FROM Teams t 
    WHERE t.TeamID = p_TeamID;
END //

-- Procedure to get revenue report for venue owner
CREATE PROCEDURE GetVenueRevenueReport(
    IN p_OwnerID INT,
    IN p_StartDate DATE,
    IN p_EndDate DATE
)
BEGIN
    SELECT 
        v.VenueID,
        v.VenueName,
        v.Location,
        COUNT(p.PaymentID) as TotalBookings,
        COALESCE(SUM(p.Amount), 0) as TotalRevenue,
        AVG(p.Amount) as AvgBookingValue,
        MAX(p.PaymentDate) as LastBooking
    FROM Venues v
    LEFT JOIN Bookings b ON v.VenueID = b.VenueID 
                        AND b.BookingDate BETWEEN p_StartDate AND p_EndDate
                        AND b.Status IN ('Confirmed', 'Completed')
    LEFT JOIN Payments p ON b.BookingID = p.BookingID 
                        AND p.PaymentStatus = 'Success'
    WHERE v.OwnerID = p_OwnerID
    GROUP BY v.VenueID, v.VenueName, v.Location
    ORDER BY TotalRevenue DESC;
END //

DELIMITER ;

-- ================================================
-- 3. NOTIFICATION SYSTEM PROCEDURES
-- ================================================

DELIMITER //

-- Procedure to send notification to user
CREATE PROCEDURE SendNotification(
    IN p_UserID INT,
    IN p_Title VARCHAR(200),
    IN p_Message TEXT,
    IN p_Type VARCHAR(20),
    IN p_EntityType VARCHAR(50),
    IN p_EntityID INT
)
BEGIN
    INSERT INTO Notifications (UserID, Title, Message, Type, RelatedEntityType, RelatedEntityID)
    VALUES (p_UserID, p_Title, p_Message, p_Type, p_EntityType, p_EntityID);
    
    SELECT LAST_INSERT_ID() as NotificationID, 'Notification sent successfully' as Status;
END //

-- Procedure to mark notifications as read
CREATE PROCEDURE MarkNotificationsAsRead(
    IN p_UserID INT,
    IN p_NotificationIDs TEXT
)
BEGIN
    SET @sql = CONCAT('UPDATE Notifications SET IsRead = TRUE, ReadAt = NOW() WHERE UserID = ', p_UserID, ' AND NotificationID IN (', p_NotificationIDs, ')');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SELECT ROW_COUNT() as UpdatedCount, 'Notifications marked as read' as Status;
END //

DELIMITER ;

-- ================================================
-- 4. ANALYTICS AND REPORTING VIEWS
-- ================================================

-- View for popular venues
CREATE OR REPLACE VIEW PopularVenuesView AS
SELECT 
    v.VenueID,
    v.VenueName,
    v.Location,
    COUNT(b.BookingID) as TotalBookings,
    COALESCE(SUM(p.Amount), 0) as TotalRevenue,
    COALESCE(AVG(f.Rating), 0) as AverageRating,
    COUNT(f.FeedbackID) as TotalReviews
FROM Venues v
LEFT JOIN Bookings b ON v.VenueID = b.VenueID AND b.Status IN ('Confirmed', 'Completed')
LEFT JOIN Payments p ON b.BookingID = p.BookingID AND p.PaymentStatus = 'Success'
LEFT JOIN Feedback f ON v.VenueID = f.VenueID
GROUP BY v.VenueID, v.VenueName, v.Location
ORDER BY TotalBookings DESC, AverageRating DESC;

-- View for team statistics
CREATE OR REPLACE VIEW TeamStatsView AS
SELECT 
    t.TeamID,
    t.TeamName,
    s.SportName,
    u.Name as CaptainName,
    COUNT(tm.MemberID) as MemberCount,
    COUNT(m.MatchID) as TotalMatches,
    SUM(CASE WHEN m.WinnerTeamID = t.TeamID THEN 1 ELSE 0 END) as Wins
FROM Teams t
JOIN Sports s ON t.SportID = s.SportID
JOIN Users u ON t.CaptainID = u.UserID
LEFT JOIN TeamMembers tm ON t.TeamID = tm.TeamID AND tm.IsActive = TRUE
LEFT JOIN Matches m ON (t.TeamID = m.Team1ID OR t.TeamID = m.Team2ID) AND m.Status = 'Completed'
GROUP BY t.TeamID, t.TeamName, s.SportName, u.Name;

-- View for user engagement metrics
CREATE OR REPLACE VIEW UserEngagementView AS
SELECT 
    u.UserID,
    u.Name,
    r.RoleName,
    COUNT(DISTINCT b.BookingID) as TotalBookings,
    COUNT(DISTINCT tm.TeamID) as TeamsJoined,
    COUNT(DISTINCT f.FeedbackID) as FeedbackGiven,
    MAX(ual.CreatedAt) as LastActivity,
    COALESCE(SUM(p.Amount), 0) as TotalSpent
FROM Users u
JOIN Roles r ON u.RoleID = r.RoleID
LEFT JOIN Bookings b ON u.UserID = b.UserID
LEFT JOIN TeamMembers tm ON u.UserID = tm.UserID AND tm.IsActive = TRUE
LEFT JOIN Feedback f ON u.UserID = f.UserID
LEFT JOIN UserActivityLog ual ON u.UserID = ual.UserID
LEFT JOIN Payments p ON u.UserID = p.UserID AND p.PaymentStatus = 'Success'
GROUP BY u.UserID, u.Name, r.RoleName;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================

SELECT 'Advanced Features Implemented Successfully!' as Status,
       'Data Validation Triggers: Added' as ValidationTriggers,
       'Business Logic Procedures: Added' as BusinessProcedures,
       'Notification System: Added' as NotificationSystem,
       'Analytics Views: Added' as AnalyticsViews,
       'Production Ready Features: Complete' as ProductionStatus;